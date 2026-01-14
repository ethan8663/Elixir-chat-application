# TCP Chat Application (Elixir)

A multi-client TCP chat server where clients connect via TCP, register nickname, list users, send direct messages and broadcasts messages to groups.  

## How to run locally

### Prerequisites
- Elixir + Erlang installed

### Start Mix project(Terminal 1)

From the project root:
```bash
cd chat 
iex --sname homer -S mix
```

### Start Server node(Terminal 2)
```bash
cd chat_server
iex --sname bart
```

Inside IEx
```elixir
Node.ping(:"homer@<your-host>")
# should return :pong
```

```elixir
Chat.ProxyServerSupervisor.start_proxy_server()
# Start proxy server
```

### Start client(Terminal 3)
```bash
cd chat_client
elixir client.exs
```

Start multiple clients in separate terminals to test.

## Commands

Commands are case-insensitive

### `/NCK <nickname>`
Set or change a nickname.

- Must start with alphabet optionally followed by alphanemeric or underscore. Up to 10 characters.

- Fail when the nickname is taken. 

Example:

/nck homer 

### `/LST`
Show list of registered nicknames. 

Example:

/LST

### `/MSG <recipients> <message>`
Send message to recipients. 

- Must set nickname first. 

Examples:

/MSG homer hello homer 

/msg homer,bart hello simpson!

### `/GRP <groupname> <users>`
Register a group for registered users.

- Group name must start with # followed by alphabet and optionally followed by alphanumeric or underscore character. Up to 11 characters.

Example:

/GRP #simpson homer,bart

/MSG #simpson hello simpson! 

## Design
- Supervision tree includes `Chat.ProxyServerSupervisor` and `Chat.Server`.
- `ProxyServer` acts as a TCP acceptor.
- A `Proxy` process is spawned per client connection.

More details: `docs/DESIGN.md`.


