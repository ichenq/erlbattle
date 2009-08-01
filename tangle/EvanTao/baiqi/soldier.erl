%% սʿ����
%% ����2�����̣�cerebelС�Ը��𷢳����nervous�񾭼������ִ�����

%% �������2������
%% move(point):     �ƶ���ĳһ��{x, y}
%% attack(point):  ����ĳһ��{x, y}
%% ����֪����ô����2�������ֽ�ɱ�׼��forward��8������(��cereble�ֽ�, nervousִ��)

%% �ϼ��Ὣһϵ�е���2����������������սʿִ��
%% �磺
%%   1 �ƶ���A��
%%   2 �ƶ���B��
%%   3 ����C��

%% attack(point):   սʿ����ѡ��·�߽��й���

-module(soldier).
-include("schema.hrl").

-export([start/3]).

start(Soldier, ChannelProc, CmdQueue) ->
    process_flag(trap_exit, true),
    
    CerebelProc = spawn_link(cerebel, start, [Soldier, ChannelProc]),
    spawn_link(nervous, start, [Soldier, CmdQueue, CerebelProc]),
    
    {SoldierId, _Side} = Soldier#soldier.id,
    loop(SoldierId, CerebelProc).

loop(SoldierId, CerebelProc) ->
    receive
        {'Move', Position, CmdSender} ->
            loop(SoldierId, CerebelProc);
            
        {'Attack', SoldierEnemy, CmdSender} ->
            CerebelProc ! {'Attack', SoldierEnemy, CmdSender},
            
            loop(SoldierId, CerebelProc);
            
        {'EXIT', _From, _Reason} ->
            io:format("   = soldier[~p] exited~n", [SoldierId]);

        _Other ->
            loop(SoldierId, CerebelProc)
            
    after 10 ->
        loop(SoldierId, CerebelProc)
    end.

