import time, os, base58, logging
from aiohttp import ClientSession
from ..rpc import rxd as rpc_rxd
from ..consensus.merkle import merkle_root_from_txids_le, merkle_branch_for_index0
from ..consensus.coinbase import build_coinbase
from ..consensus.targets import (
    target_to_diff1,
)

logger = logging.getLogger(__name__)


async def update_once(state, settings, http: ClientSession, force_update: bool = False):
    ROLL_SECONDS = getattr(settings, "ntime_roll", 30)

    js = await rpc_rxd.getblocktemplate(http, settings.node_url)
    if js.get("error"):
        raise RuntimeError(js["error"])
    r = js["result"]
    version_int = r["version"]
    height_int = r["height"]
    bits_hex = r["bits"]
    prev_hash_hex = r["previousblockhash"]
    txs_list = r["transactions"]
    coinbase_sats_int = r["coinbasevalue"]
    target_hex = r["target"]

    ts = int(time.time())
    state.bits = bits_hex
    state.version = version_int

    # Store prevHash - Radiant uses standard Bitcoin-style prevhash
    # Convert hex to bytes in little-endian format
    prev_hash_bytes = bytes.fromhex(prev_hash_hex)[::-1]  # Convert BE hex to LE bytes
    
    # For stratum, we need the prevhash split into 4-byte words, each word byte-swapped
    prevhash_words_le = []
    prevhash_words_be = []
    for i in range(0, 32, 4):  # 32 bytes total, 4 bytes per word
        word = prev_hash_bytes[i : i + 4]
        prevhash_words_be.append(word)
        prevhash_words_le.append(word[::-1])

    state.prevHash_be = b"".join(prevhash_words_be)
    state.prevHash_le = b"".join(prevhash_words_le)

    new_block = state.height == -1 or state.height != height_int
    if new_block:
        state.height = height_int

    state.target = target_hex

    roll_due = (state.timestamp == -1) or (state.timestamp + ROLL_SECONDS <= ts)
    if new_block or roll_due:
        proxy_sig = (settings.proxy_signature or "/radiant-stratum-proxy/").encode(
            "utf-8"
        )
        arbitrary = proxy_sig

        outputs_extra = []
        # Radiant may have miner fund or other extra outputs
        miner_fund = r.get("minerfund")
        if miner_fund and "outputs" in miner_fund:
            for output in miner_fund["outputs"]:
                if "script" in output and output.get("value", 0) > 0:
                    outputs_extra.append((output["value"], bytes.fromhex(output["script"])))

        if not state.pub_h160:
            return False

        (
            coinbase_tx,
            coinbase_txid,
            coinbase1,
            coinbase2,
            coinbase1_nowit,
            coinbase2_nowit,
        ) = build_coinbase(
            pub_h160=state.pub_h160,
            height=state.height,
            arbitrary=arbitrary,
            miner_value=coinbase_sats_int,
            outputs_extra=outputs_extra,
        )
        state.coinbase_tx = coinbase_tx
        state.coinbase_txid = coinbase_txid
        state.coinbase1 = coinbase1
        state.coinbase2 = coinbase2
        state.coinbase1_nowit = coinbase1_nowit
        state.coinbase2_nowit = coinbase2_nowit

        incoming_txs = []
        txids = [state.coinbase_txid]
        for tx in txs_list:
            incoming_txs.append(tx["data"])
            txids.append(bytes.fromhex(tx["txid"])[::-1])
        state.externalTxs = incoming_txs

        merkle = merkle_root_from_txids_le(txids)
        state.coinbase_branch = merkle_branch_for_index0(txids)
        state.merkle_branches = [h.hex() for h in state.coinbase_branch]

        state.bits_le = bytes.fromhex(bits_hex)[::-1]
        state.timestamp = ts

        # Use epoch timestamp as job ID
        state.job_counter = ts

        # Network difficulty (diff1-scaled) based on target
        t_int = int(state.target, 16)
        network_diff = target_to_diff1(t_int)
        state.advertised_diff = network_diff

        # Per-share difficulty we tell miners (scaled by divisor)
        difficulty = network_diff / settings.share_difficulty_divisor

        clean = not roll_due or new_block
        job_params = [
            hex(state.job_counter)[2:],
            state.prevHash_le.hex(),
            state.coinbase1_nowit.hex(),
            state.coinbase2_nowit.hex(),
            state.merkle_branches,
            version_int.to_bytes(4, "big").hex(),
            bits_hex,
            ts.to_bytes(4, "big").hex(),
            clean,
        ]

        alive = set()
        for sess in list(state.all_sessions):
            try:
                setattr(sess, "_share_difficulty", difficulty)
                await sess.send_notification("mining.set_difficulty", (difficulty,))
                await sess.send_notification("mining.notify", job_params)
            except Exception as e:
                state.logger.debug("Dropping dead session %r: %s", sess, e)
                try:
                    wid = getattr(sess, "_worker_id", None)
                    if wid:
                        from ..stratum.session import hashrate_tracker

                        hashrate_tracker.remove_worker(wid)
                except Exception as e:
                    logger.debug(
                        "Failed to remove worker %s from hashrate tracker: %s", wid, e
                    )
            else:
                alive.add(sess)
        state.all_sessions = alive

        for sess in list(state.new_sessions):
            try:
                setattr(sess, "_share_difficulty", difficulty)
                await sess.send_notification("mining.set_difficulty", (difficulty,))
                await sess.send_notification("mining.notify", job_params)
                state.all_sessions.add(sess)
            except Exception as e:
                state.logger.debug("Failed initializing new session %r: %s", sess, e)
        state.new_sessions.clear()

    return True


async def state_updater_loop(state, settings):
    from aiohttp import ClientSession
    import asyncio

    async with ClientSession() as http:
        while True:
            try:
                await update_once(state, settings, http)
            except Exception as e:
                state.logger.critical("State updater error: %s", e)
                await asyncio.sleep(5)

            # Adjust sleep based on ZMQ availability
            if getattr(settings, "enable_zmq", False):
                await asyncio.sleep(10.0)
            else:
                await asyncio.sleep(0.1)
