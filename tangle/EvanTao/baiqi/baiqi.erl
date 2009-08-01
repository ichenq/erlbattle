%%% ָ�ӹٽ��̡�
%%% ���ɸ���սʿ���̣�������ս�Բ�ε�ָ�ӡ�
%%% ��ֳ�2�Ӱ�����1�ӽ���1��֧Ԯ������

-module(baiqi).
-include("schema.hrl").
-include("baiqi.hrl").

%% �ⲿ����
-export([run/3]).

run(ChannelProc, Side, CmdQueue) ->
    process_flag(trap_exit, true),
    
    Army = ?PreDef_army,
    
    NewArmy = create_soldier(ChannelProc, Side, CmdQueue, Army),
    CorporalProc = spawn_link(corporal, start, [self(), Side, NewArmy]),
    
    %% ���ɹ���
    CorporalProc ! {'AttackAuto', self()},
    
    loop(CorporalProc).

%% ��ÿ��սʿ�������һ��սʿ���̣�����¼���̺ţ����ش洢����Ϣ�����б�
create_soldier(ChannelProc, Side, CmdQueue, Army) ->
    create_soldier(ChannelProc, Side, CmdQueue, Army, []).

create_soldier(ChannelProc, Side, CmdQueue, [SoldierId|RestSoldierIdes], NewArmy) ->
    Soldier = baiqi_tools:get_soldier_by_id_side(SoldierId, Side),
    Soldier_baiqi = #soldier_baiqi{id=SoldierId, pid=spawn_link(soldier, start, [Soldier, ChannelProc, CmdQueue])},
    create_soldier(ChannelProc, Side, CmdQueue, RestSoldierIdes, [Soldier_baiqi|NewArmy]);
create_soldier(_ChannelProc, _Side, _CmdQueue, [], NewArmy) ->
    NewArmy.

loop(CorporalProc) ->
    receive
        {'EXIT', _From, _Reason} ->
            %if
            %    From == CorporalProc -> io:format("==== baiqi army go home~~~~~~~n");
            %    true -> none%loop(CorporalProc)
            %end,
            io:format("==== baiqi army go home~~~~~~~n");
            
        _Other ->
            loop(CorporalProc)
    
        after 1000*3600 ->
            loop(CorporalProc)
    end.
