-module(soldier).

%% �ⲿ����
-export([start/1]).


%% SoldierInfo = {ChannelProc, Id, Side}
start(SoldierInfo) ->
    %{ChannelProc, SoldierId, Side} = SoldierInfo,
    process_flag(trap_exit, true),
    
    loop(SoldierInfo),
    none.
    
%% ChannelProc ! {command, Cmd, SoldierId, 0, get_random_seq()};    
    
%% �ӿں���
%% �ƶ�
%% ��8�������ƶ�һ��
move(Position) ->
    none.

%% ����
attack() ->
    none.


%% ��ѭ��    
loop(SoldierInfo) ->
    {ChannelProc, SoldierId, Side} = SoldierInfo,
    receive
        {'EXIT', _From, _Reason} ->
            io:format("==== ai soldier[~p]~~~~~~~n", [SoldierId]);
            
        _Other ->
            loop(SoldierInfo)
    
        after 100 ->
            loop(SoldierInfo)
    end.
    