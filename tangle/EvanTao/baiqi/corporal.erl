%%% ͨѶ�ٽ��̡�
%%% ����ָ�ӹٵ�����ֽ��ս����ε�һϵ������
%%% ���ȵ�A�㣬�ٵ�B���

-module(corporal).
-include("schema.hrl").
-include("baiqi.hrl").

-export([start/3]).

start(CommanderProc, Side, Army) ->
    process_flag(trap_exit, true),
    
    loop(CommanderProc, Side, Army).

%% ����ָ�ӹٷ���������ֽ������սʿ��������
%% ����սʿ/�ӳ���������Ϣ�����д�����ָ��սʿ/�ӳ�
loop(CommanderProc, Side, Army) ->
    receive
        %% ָ�ӹٷ��������ɹ���������
        %% ��ÿ��սʿѡ����ˣ�����սʿ����attack/1ָ��
        {'AttackAuto', CommanderProc} ->
            attack_auto(Side, Army),

            loop(CommanderProc, Side, Army);

        {'EXIT', _From, _Reason} ->
            io:format("   = corporal exited~n");

        _Other ->
            loop(CommanderProc, Side, Army)

        after 10 ->
            loop(CommanderProc, Side, Army)
    end.

attack_auto(Side, Army) ->
    lists:foreach(
        fun(Soldier_baiqi) ->
            %% ����ҳ�����
            %%   �ҳ����е���
            EnemySide = if
                            Side == "red"   -> "blue";
                            true            -> "red"
                        end,
            EnemyArmy = baiqi_tools:get_soldier_by_side(EnemySide),
            
            %%   �����ȡ
            EnemySoldier = lists:nth(baiqi_tools:get_random(length(EnemyArmy)), EnemyArmy),
            % {soldier,{6,"blue"},{14,7},100,"west","wait",0,0}

            %% ָ�Ӹ�սʿ����
            Soldier_baiqi#soldier_baiqi.pid ! {'Attack', EnemySoldier, self()}
        end,
        Army).
