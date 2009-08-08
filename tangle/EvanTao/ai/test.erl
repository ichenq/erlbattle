-module(test).
-include("schema.hrl").

%% �ⲿ����
-export([run/3]).

%% start_pos = {X, Y}   ��ʼλ��
%% stop_pos = {X, Y}    Ŀ��λ��
%% path_col = path_row = [] ·����X���Ϻ�Y����
-record(path_array, {start_pos, stop_pos, path_col, path_row}).

run(ChannelProc, Side, CmdQueue) ->
    process_flag(trap_exit, true),
    
    

    loop().

loop() ->
    
    receive
        {'EXIT', _From, _Reason} ->
            io:format("==== ai army go home~~~~~~~n");
            
        _Other ->
            loop()
    
        after 10 ->
            loop()
    end.ai.erl

build_path() ->
    none.
