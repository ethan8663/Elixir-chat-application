## Design
Supervisor has children of 2 dynamic supervisors: Chat.ProxyServerSupervisor and Chat.Server.
Chat.ProxyServerSupervisor creates and monitors ProxyServer on demand.
Chat.Server creates and monitors Proxy on demand. 

2 ets tables. :chat_group_count and :chat_groups
:chat_group_count is for group name and number of group members 
:chat_groups is for group name and client's pid 

1 registry. Nickname is associated with proxy's pid. 

ProxyServer is acceptor. It can listen to many different ports(default 6666).
Proxy is created when new client is accepted(one proxy per one clinet).

## How to start the application
Start mix project
cd chat 
iex --sname homer -S mix 

Start 2 acceptors
cd chat_server
iex --sname bart 
Node.ping(homer)
Chat.ProxyServerSupervisor.start_proxy_server       : default port 6666
Chat.ProxyServerSupervisor.start_proxy_server(4444) : specifed port 4444

Start clients
cd chat_client
elixir client.exs                : default localhost 6666
elixir client.exs localhost 4444 : connect to localhost 4444

## Test cases
Test cases for /MSG and /GRP (/LST, /NCK are straightforward)
This client nickname is ethan

1. Message to multiple clients but some are valid nicknames
/MSG homer, bart, marge hello world 
If only homer and marge is registered, homer and marge receive message. Client ethan receives error message for unregistered bart.

2. New group creation, client exit, group deletion
/GRP #group1 ethan, homer
Ets tables(:chat_group_count and :chat_groups) will be affected.

:chat_group_count
1 row inserted {"group1", 2} (group name, count)
:chat_groups
2 rows inserted {"group1", ethan pid}, {"group1", homer pid}

If homer exits, ets tables will be affected.
:chat_group_count
1 row affected {"group1", 1}
:chat_groups
1 row deleted {"group1", ethan pid}

If ethan exists, ets tables will be affected.
:chat_group_count
1 row deleted (group1 has no member -> delete group -> log group deleted)
:chat_groups
1 row deleted 


## Bug report
1. Executing /grp #g1 ethan and then executing /grp #g1 ethan again will result in :chat_group_count table {"group1", 2}. That table does not check whether the member is already in the group or not. This leads to failing to delete group when all members exist. 


