# Chat UX Feature Checklist

Use this before designing chat-heavy products. A chat design is incomplete unless it covers message actions, composer states, media, moderation, and delivery/read state UX.

## Message timeline

- Message groups by sender/time, date separators, avatar/name visibility rules.
- Own vs other bubble styles, max width ~72-75%.
- Text, image grid, video/document, link preview, invite-link card, system/deleted message placeholders.
- Timestamp, delivery/read state, edited/deleted indicators where applicable.
- Reaction display under bubble, max compact reactions plus detail affordance.
- Pinned marker on pinned messages.
- Reply quote rendered inside bubble with sender, snippet, optional thumbnail.

## Message actions

Design long-press/context menu and swipe shortcut:

- Reply.
- Copy text/image.
- Pin/unpin.
- Delete.
- Delete for me.
- Delete for everyone when permission allows.
- Report in public/livestream contexts.
- Add friend / cancel request from public/live sender where relevant.
- Ban member for admin/owner where relevant.

## Pinned messages

- Top pinned banner with current pinned item, carousel/count if multiple.
- Tap banner opens pinned list bottom sheet.
- Pinned list includes sender, date, text/media preview, jump-to-message, unpin action.
- Unpin confirmation/action sheet.
- Empty pinned state if needed.

## Reply UX

- Swipe-to-reply affordance.
- Composer reply preview with vertical accent bar, sender name, text/media preview, close/cancel.
- Bubble quote preview above content.
- Tap quote jumps to original message if available, otherwise shows unavailable state.

## Composer

- Attachment button.
- Multiline text field, 3000 char limit or visible long-text handling.
- Emoji toggle/picker.
- Send button appears/enables only with text/media.
- Copied/pasted image preview before send.
- Upload progress, failed upload retry/remove.
- Offline queued message state.

## Read receipts

- Group/mini-room read receipt bottom sheet with loading, empty, user grid/list.
- Own outgoing message affordance to open viewers.

## Moderation / permissions

- Owner/admin-specific actions: pin, unpin, delete for everyone, ban member.
- User actions: delete for me, report, add friend.
- Disabled/hidden actions based on message type, invite links, deleted messages, and role.

## Audit bar

For every chat redesign deliverable, include at least:

1. Normal timeline.
2. Long-press action menu.
3. Reply composer state.
4. Pinned banner + pinned list sheet.
5. Delete action sheet.
6. Reaction picker/display.
7. Read receipts sheet.
8. Media/image upload state.
9. Deleted message placeholder.
10. Offline/reconnect queued state.
