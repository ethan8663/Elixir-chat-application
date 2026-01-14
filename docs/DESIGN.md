# Design

## Supervision structure
- The application supervises:
  - `Chat.ProxyServerSupervisor` (DynamicSupervisor)
  - `Chat.Server` (DynamicSupervisor)

### Responsibilities
- `Chat.ProxyServerSupervisor`
  - Creates and monitors `ProxyServer` processes on demand.
- `Chat.Server`
  - Creates and monitors `Proxy` processes on demand.

## Core components

### ProxyServer (TCP acceptor)
- Listens on one or more TCP ports (default `6666`).
- Accepts client connections and spawns one `Proxy` per client.

### Proxy (per-client process)
- One `Proxy` is created per accepted client connection.
- Handles client commands.

## Data storage

### ETS tables
- `:chat_group_count`
  - Key: group name
  - Value: number of members in the group
- `:chat_groups`
  - Key: group name
  - Value: client pid (multiple rows per group)

### Registry
- Nickname is associated with a proxy pid (nickname → proxy pid).
