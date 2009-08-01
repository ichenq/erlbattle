%% ��ϵͳ
%% ��鶯��������

-module(nervous).
-include("schema.hrl").

-export([start/3]).

start(Soldier, CmdQueue, CarebelProc) ->
    process_flag(trap_exit, true),

    loop(CarebelProc, Soldier, CmdQueue).

loop(CarebelProc, Soldier, CmdQueue) ->
    send_msg(CarebelProc, Soldier, CmdQueue),
    
    receive
        {'EXIT', _From, _Reason} ->
            {SoldierId, _Side} = Soldier#soldier.id,
            io:format("   = nervous[~p] exited~n", [SoldierId]);
            
        _Other ->
            loop(CarebelProc, Soldier, CmdQueue)
            
    after 50 ->
        loop(CarebelProc, Soldier, CmdQueue)
    end.

%% ���Ͷ��������Ϣ
send_msg(CarebelProc, Soldier, CmdQueue) ->
    case get_action_status(Soldier, CmdQueue) of
        'ActionDone' ->
            CarebelProc ! 'ActionDone';
         
        'ActionDoing' ->
            CarebelProc ! 'ActionDoing';
            
        'DestUnreachable' ->
            CarebelProc ! 'DestUnreachable';
        
        _default ->
            none
    end.

%% ��⶯��
%% ActionDone �������
%% ActionDoing �������ڽ���

%% ֻ��鶯���Ƿ���ɡ�
get_action_status(Soldier, CmdQueue) ->
    {SoldierId, Side} = Soldier#soldier.id,
    CmdInfo = baiqi_tools:get_soldier_cmd(SoldierId, CmdQueue),
    Soldier_we = baiqi_tools:get_soldier_by_id_side(SoldierId, Side),
    if 
        CmdInfo == [] ->  %% ����������޴�սʿ������
            if
                Soldier_we == none ->  %% ս�����޴�սʿ
                    none;
                    
                true -> %% �ҵ�սʿ
                    case Soldier_we#soldier.action of
                        "wait" ->
                            'ActionDone';
                        
                        _Other ->
                            none
                    end
                    
            end;
            
        true -> %% ���������д�սʿ������
                %% ÿ��սʿ�Ķ��г���Ϊ1��������δִ�С��ٴη�������������
            %io:format("cmd[~p] is in queue~n", [CmdInfo#command.name]),
            'ActionDoing'
            
    end.

