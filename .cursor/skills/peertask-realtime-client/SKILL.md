---
name: peertask-realtime-client
description: Client-side SyncEngine, Socket.IO signaling, WebRTC DataChannel, and operation catch-up. Use when changing P2P, cursors, or collaborative canvas on the Flutter client.
---

# Realtime (client)

## Online flow

```
BoardScreen
  → SignalingService.connect(jwt) → join_room(boardId)
  → room_joined { peers } → WebRTC via signal
  → DataChannel: Operation JSON
  → SyncEngine.receiveOperation
  → ApiService.saveOperation if _saveBackend
  → GET /operations/board/:id?since= for catch-up
```

## Events (client)

- Emit: `join_room` (`boardId` string), `leave_room`, `signal` `{ to, signal }`, `update_mic_status`
- Listen: `room_joined`, `peer_joined`, `peer_left`, `signal`, `peer_mic_updated`

Offline (no JWT): `create_room` / `join_room` `{ roomCode, userName }`. Do not call workspace/board REST.

## SyncEngine (`lib/core/sync_engine.dart`)

- Dedup `_appliedOpIds`
- Types: `createObject`, `updateObject`, `deleteObject`, `moveObject`, `resizeObject`
- LWW: skip update if `timestamp < existing.updatedAt`
- Not in `_objects`: `stroke`, `text`, `rectangle`, `circle`, `line`, `cursor`, `task`
- Cursors: `shouldSaveBackend: false`

## Files

`signaling_service.dart`, `webrtc_service.dart`, `p2p/p2p_manager.dart`, `web_p2p_service*.dart`, `native_p2p_service*.dart`, `models/operation/`.
