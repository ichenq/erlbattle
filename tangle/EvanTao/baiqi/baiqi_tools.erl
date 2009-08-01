-module(baiqi_tools).
-include("schema.hrl").
-include("baiqi.hrl").

-compile(export_all).

%% �õ������
%% ��Χ�� 1 �� Value
get_random(Value) ->
    {A, B, C} = now(),
	random:seed(A, B, C),
    random:uniform(Value).

%% �Զ���forѭ��
for(Max, Max, F) -> F(Max);
for(I, Max, F) -> F(I), for(I+1, Max, F).

%% �����������Ӽ�ľ���
get_distance({X1,Y1}, {X2,Y2}) ->
	abs(X1 - X2) + abs(Y1 - Y2).

%% ����ָ�����

%% ����սʿ��ŵõ�������սʿ������
get_soldier_cmd(SoldierId, QueueId) ->
    Pattern = #command{
                        soldier_id      = SoldierId,
                        name            = '_',
                        execute_time    = '_',
                        execute_seq     = '_',
                        seq_id          = '_'
                        },

    ets:select(QueueId, [{Pattern, [], ['$_']}]).


%% ս����Ϣ��

%% ����ս�ӵõ�սʿ(0/n)
get_soldier_by_side(Side) ->
    Pattern = #soldier{
                        id              = {'_', Side},
                        position        = '_',
                        hp              = '_',
                        facing          = '_',
                        action          = '_',
                        act_effect_time = '_',
                        act_sequence    = '_'
                        },
                        
    ets:select(battle_field, [{Pattern, [], ['$_']}]).
    
%% ����սʿID��ս�ӵõ�սʿ(0/1)
get_soldier_by_id_side({SoldierId, Side}) ->
    get_soldier_by_id_side(SoldierId, Side).
    
get_soldier_by_id_side(SoldierId, Side) ->
    Pattern = #soldier{
                        id              = {SoldierId, Side},
                        position        = '_',
                        hp              = '_',
                        facing          = '_',
                        action          = '_',
                        act_effect_time = '_',
                        act_sequence    = '_'
                        },
                        
    case ets:select(battle_field, [{Pattern, [], ['$_']}]) of
        [Soldier] -> Soldier;
        [] -> none
    end.
        

%% ���������õ�սʿ(0/1)
get_soldier_by_position(Position) ->
    Pattern = #soldier{
                        id              = '_',
                        position        = Position,
                        hp              = '_',
                        facing          = '_',
                        action          = '_',
                        act_effect_time = '_',
                        act_sequence    = '_'
                        },
                        
    case ets:select(battle_field, [{Pattern, [], ['$_']}]) of
        [Soldier] -> Soldier;
        [] -> none
    end.
