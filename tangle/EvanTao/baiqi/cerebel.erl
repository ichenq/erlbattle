%% С�ԣ���������
%% �����������ֽ�ɱ�׼����
%% ǰ�� forward, ���� back,
%% ת�� turnSouth, turnNorth, turnWest,turnEast
%% ���� attack
%% ԭ�ش��� wait

-module(cerebel).
-include("schema.hrl").
-include("baiqi.hrl").

-export([start/2]).

start(Soldier, ChannelProc) ->
    process_flag(trap_exit, true),

    %% սʿ��Ŀ��
    Mission_queue = ets:new(soldier_mission_queue, [ordered_set, private, {keypos, #soldier_mission.id}]),
    %% սʿ���ж���Ϣ����
    Cmd_queue = ets:new(soldier_cmd_queue, [ordered_set, private, {keypos, #soldier_cmd.id}]),

    loop(Soldier, ChannelProc, Mission_queue, Cmd_queue).

loop(Soldier, ChannelProc, Mission_queue, Cmd_queue) ->
    receive
        'ActionDone' -> %% ������һ������
            %% ���Ŀ��δ��ɣ���ִ�У�����ȴ�
            Goal = length(ets:tab2list(Mission_queue)),
            if
                Goal > 0 ->
                    %% ���ƻ�
                    revise_plan(Soldier, Mission_queue, Cmd_queue),
            
                    %% ִ�мƻ�
                    Cmd = get_next_cmd(Mission_queue, Cmd_queue),
                    {SoldierId, _Side} = Soldier#soldier.id,
                    %io:format("==== cerebel[~p] sent a command[~p]~n", [SoldierId, Cmd]),
                    ChannelProc ! {command, Cmd, SoldierId, 0, get_random_seq()};

                true ->
                    none
            end,

            loop(Soldier, ChannelProc, Mission_queue, Cmd_queue);

        {'Attack', SoldierEnemy, CmdSender} ->
            %% ��������ƶ��ƻ�
            parse_attack(Soldier, SoldierEnemy, Mission_queue, Cmd_queue),
            %% ���ƻ�
            %revise_plan(Soldier, Mission_queue, Cmd_queue),
            %% ִ�мƻ�
            self() ! 'ActionDone',
            
            loop(Soldier, ChannelProc, Mission_queue, Cmd_queue);

        {'EXIT', _From, _Reason} ->
            %io:format("   = cerebel[~p] exited~n", [SoldierId]),
            {SoldierId, _Side} = Soldier#soldier.id;

        _Other ->
            %revise_plan(Soldier, Mission_queue, Cmd_queue),
            loop(Soldier, ChannelProc, Mission_queue, Cmd_queue)

    after 10 ->
        %revise_plan(Soldier, Mission_queue, Cmd_queue),
        loop(Soldier, ChannelProc, Mission_queue, Cmd_queue)
    end.

%% ���ָ��
get_random_cmd() ->
    case baiqi_tools:get_random(8) of
        1 -> "forward";
        2 -> "back";
        3 -> "turnSouth";
        4 -> "turnNorth";
        5 -> "turnWest";
        6 -> "turnEast";
        7 -> "attack";
        8 -> "wait"
    end.

%% �������
get_random_seq() ->
    baiqi_tools:get_random(10).

%% �����ж��ƻ�
%% ��һϵ��ָ����������
parse_attack(SoldierWe, SoldierEnemy, Mission_queue, Cmd_queue) ->
    %io:format("SoldierId=~p, Side=~p~n", [Soldier]),
    %% �ҷ�սʿ��Ϣ
    {SoldierId_we, Side_we} = SoldierWe#soldier.id,
    Soldier_we = baiqi_tools:get_soldier_by_id_side(SoldierId_we, Side_we),

    %% �趨����Ŀ��
    Soldier_mission = #soldier_mission{
                                id          = 0,
                                priority    = 1,
                                act         = "attack",
                                target      = SoldierEnemy
                            },
    ets:insert(Mission_queue, Soldier_mission),

    ets:delete_all_objects(Cmd_queue),
    gen_plan(Soldier_we, SoldierEnemy, Cmd_queue).

gen_plan(SoldierWe, SoldierEnemy, Cmd_queue) ->
    if
        %% �ҷ�սʿ����
        SoldierWe == none ->
            none;

        %% �ҷ�սʿ���
        true ->
                %io:format("Soldier:[~p]~n", [Soldier]),
            %% �ҷ�սʿλ��
            {Xwe, Ywe} = SoldierWe#soldier.position,

            %% �з�սʿ��Ϣ
            Soldier_enemy = baiqi_tools:get_soldier_by_id_side(SoldierEnemy#soldier.id),

            if
                %% ���������������Ѱ������ĵ��˻���ͬ��л�
                Soldier_enemy == none ->
                    none;

                %% ���˴�����
                true ->

                    %% �з�����λ��
                    {Xe, Ye} = Soldier_enemy#soldier.position,
                    Faced_enemy = Soldier_enemy#soldier.facing,
                    {Xenemy, Yenemy} = get_behind_pos(Faced_enemy, Xe, Ye),
                    %{Faced_enemy, Xenemy, Yenemy} = {"north", 11, 4},

                    %% ·�߶���ֱ�ߣ���ת��
                    MaxX = abs(Xwe-Xenemy),
                    MaxY = abs(Ywe-Yenemy),

                    {ActX, ActY} = confirm_direction({SoldierWe#soldier.facing, Xwe, Ywe}, {Faced_enemy, Xenemy, Yenemy}),

                    if
                        ActX == "equal" ->
                            none;

                        true ->
                            Soldier_cmd_X = #soldier_cmd{
                                id          = 0,
                                mission     = 0,
                                name        = ActX
                            },
                            ets:insert(Cmd_queue, Soldier_cmd_X)
                    end,

                    %% ֱ��
                    Lxid = lists:seq(1, MaxX),

                    lists:foreach(
                        fun(Id) ->
                            Soldier_cmd = #soldier_cmd{
                                id          = Id,
                                mission     = 0,
                                name        = "forward"
                            },
                            ets:insert(Cmd_queue, Soldier_cmd)
                        end,
                        Lxid),

                    %% ת��
                    if
                        ActY == "equal" ->
                            none;

                        true ->
                            Soldier_cmd_Y = #soldier_cmd{
                                id          = MaxX+1,
                                mission     = 0,
                                name        = ActY
                            },
                            ets:insert(Cmd_queue, Soldier_cmd_Y)
                    end,

                    %% ֱ��
                    Lyid = lists:seq(MaxX+1+1, MaxX+1+MaxY),
                    lists:foreach(
                        fun(Id) ->
                            Soldier_cmd = #soldier_cmd{
                                id          = Id,
                                mission     = 0,
                                name        = "forward"
                            },
                            ets:insert(Cmd_queue, Soldier_cmd)
                        end,
                        Lyid)
                    
                    %% �ﵽĿ�ĵغ����ж��Ƿ�Ҫת�������Ե���

            end
    end.

%% ��һ���ƶ�������һ��
%% ���ر�׼��������[forward, turEast, ...]
move_from_to({Facing, Xo, Yo}, {Faced, Xt, Yt}) ->
    {ActX, ActY} = confirm_direction({Facing, Xo, Yo}, {Faced, Xt, Yt}),
    none.
    
%% ����
attack_to({Facing, Xo, Yo}, {Faced, Xt, Yt}) ->
    {ActX, ActY} = confirm_direction({Facing, Xo, Yo}, {Faced, Xt, Yt}),
    
    if
        ActX == "equal" -> none;
        true -> none
    end,
    
    none.


gen_forward_cmd_from_list([H | T]) ->
    gen_forward_cmd_from_list([H | T], []).

gen_forward_cmd_from_list([H | T], Lxcmd) ->
    Cmd = {H, "forward"},
    gen_forward_cmd_from_list(T, [Cmd|Lxcmd]);
gen_forward_cmd_from_list([], Lxcmd) ->
    Lxcmd.

move_to_position(Soldier, Position) ->
    none.

attack_soldier(Soldier, EnemySoldierId) ->
    none.

%% ȷ��սʿ��Ŀ��֮������λ��
%% ȷ��սʿ�н��ķ���
%% Origin = Target = position = {x, y}
confirm_direction({Facing, Xo, Yo}, {Faced, Xt, Yt}) ->
    if
        Xo < Xt  ->
            if
                Facing == "east" -> ActX = "equal";
                true -> ActX = "turnEast"
            end;

        Xo == Xt -> ActX = "equal";

        Xo > Xt  ->
            if
                Facing == "west" -> ActX = "equal";
                true -> ActX = "turnWest"
            end
    end,

    if
        Yo < Yt  ->
            if
                Facing == "north" -> ActY = "equal";
                true -> ActY = "turnNorth"
            end;

        Yo == Yt -> ActY = "equal";

        Yo > Yt  ->
            if
                Facing == "south" -> ActY = "equal";
                true -> ActY = "turnSouth"
            end
    end,
    {ActX, ActY}.

%% ȡһ������ִ��
%% ���������û��������Ĭ��Ϊwait
get_next_cmd(Mission_queue, Cmd_queue) ->
    Key = ets:first(Cmd_queue),
    %io:format("Key=~p~n", [Key]),
    %ets:select_delete(soldier_cmd, {Key, '_Name'}),
    %io:format(ets:i(Cmd_queue)),
    if
        Key == '$end_of_table' ->
            Cmd = "wait";
        true ->
            Soldier_cmd = lists:nth(1, ets:select(Cmd_queue, [{#soldier_cmd{id = Key, mission = '_', name = '_'}, [], ['$_']}])),
            Cmd = Soldier_cmd#soldier_cmd.name,
            
            ets:delete(Cmd_queue, Key),
            %% �����һ����¼�����ô���ˣ��������һ����¼��˵��mission����������ˡ����������ɾ����
            case ets:next(Cmd_queue, Key) of
                '$end_of_table' ->
                    ets:delete(Mission_queue, Soldier_cmd#soldier_cmd.mission);

                Key_next ->
                    %io:format("Key_next=~p~n", [Key_next]),
                    none
            end
    end,
    %io:format("Cmd=~p~n", [Cmd]),
    %io:format("Key=~p, Cmd=~p~n", [Key, Cmd]),
    Cmd.

%% �鿴��һ������
view_next_cmd(Mission_queue, Cmd_queue) ->
    Key = ets:first(Cmd_queue),
    if
        Key == '$end_of_table' ->
            Cmd = "wait";
        true ->
            Soldier_cmd = lists:nth(1, ets:select(Cmd_queue, [{#soldier_cmd{id = Key, mission = '_', name = '_'}, [], ['$_']}])),
            Cmd = Soldier_cmd#soldier_cmd.name
    end,
    Cmd.

%% ���һ�������Ƿ���ִ�гɹ�
%% ת��϶��ɹ�
%% ������ǰ����������Ҫ����Ŀ��λ���Ƿ����ˣ������Ƿ�Ҫ�ͱ�������ͬһ��λ��
check_cmd(Soldier, Cmd, Mission_queue, Cmd_queue) ->
    %% �õ�սʿ��ǰλ�á�������Чʱ��
    Soldier_we = baiqi_tools:get_soldier_by_id_side(Soldier#soldier.id),
    {Facing, {Xo, Yo}} = {Soldier_we#soldier.facing, Soldier_we#soldier.position},
    
    %io:format("action=~p, act_effect_time=~p~n", [Soldier_we#soldier.action, Soldier_we#soldier.act_effect_time]),
    
    %Cmd_in_queue = baiqi_tools:get_soldier_cmd(SoldierId, ),
    
    %% �õ�ǰ��ĸ���
    {Xt, Yt} = get_future_pos(Cmd, Facing, {Xo, Yo}),
    
    %% ��ǰ�ĸ����Ƿ��е���
    Soldier_enemy = baiqi_tools:get_soldier_by_position({Xt, Yt}),
    if
        %% ǰ��û�ˣ�Ԥ��
        Soldier_enemy == none ->
            %% �ж�Ŀ������Ƿ�����ϰ�
            
            %% �õ�{Xo, Yo}Ŀ��{Xt, Yt}��Χ������3������
            L_round_pos = get_around_pos({Xo, Yo}, {Xt, Yt}),
            %io:format("ori=~p, des=~p~nround=~p~n", [{Xo, Yo}, {Xt, Yt}, L_round_pos]),
            %io:format("ori=~p, des=~p, penemy=~p~n", [{Xo, Yo}, {Xt, Yt}]),
            %io:format("round = ~p~n", [length(L_round_pos)]),

            L_future_facing = check_future_pos({Xt, Yt}, Soldier_we#soldier.act_effect_time, L_round_pos);
            %io:format("L_future_facing=~p~n", [L_future_facing]),
            
        true ->
            FacingEnemy = Soldier_enemy#soldier.facing,
            %L_future_facing = [Soldier_enemy#soldier.facing]
            L_future_facing = [FacingEnemy]
    end, 
    
    %% ���Ŀ������ˣ��Ҳ�������棬�͹�����������·
    %% ���û�ˣ���ǰ��(������ĳ�����Ѱ��Ŀ��)
    EnemyCount = length(L_future_facing),
    if 
        %% ��һ�����򹥻���
        EnemyCount == 1 ->
            [FacingFuture] = L_future_facing,
            Is_face2face = is_face2face(FacingFuture, Facing),
            if
                %% ��������·
                Is_face2face == true -> Ret = 'detour';
                %% ���򹥻�
                true -> Ret = 'attack'
            end;

        %% û�˻��߶��˾�����
        true ->
            if
                Cmd == "attack" -> Ret = 'search';
                true -> Ret = 'none'
            end
    end,
    Ret.

is_face2face(Face1, Face2) ->
    {Face1, Face2} == {"east", "west"} orelse
    {Face1, Face2} == {"west", "east"} orelse
    {Face1, Face2} == {"south", "north"} orelse
    {Face1, Face2} == {"north", "south"}.

%% �õ���{Xo, Yo}��������һ������λ��
get_future_pos(Cmd, Facing, {Xo, Yo}) ->
    case Cmd of
        "back"      ->
            {Xt, Yt} = get_behind_pos(Facing, Xo, Yo);
        "attack"    ->
            {Xt, Yt} = get_ahead_pos(Facing, Xo, Yo);
        "forward"   ->
            {Xt, Yt} = get_ahead_pos(Facing, Xo, Yo);
        _Else       ->
            {Xt, Yt} = {Xo, Yo}
    end,
    {Xt, Yt}.
    
%% ���ÿ�����ӵ�Ԥ�����
%% ��Tʱ��ʱ�Ƿ����˵���/�뿪�������
check_future_pos({Xt, Yt}, TimeFuture, L_round_pos) ->
    %io:format("L_round_pos:~p~n", [L_round_pos]),
    check_future_pos({Xt, Yt}, TimeFuture, L_round_pos, []).
    
check_future_pos({_X, _Y}, _TimeFuture, [], Result) ->
    Result;
check_future_pos({Xt, Yt}, TimeFuture, [H|T], Result) ->
    %% Ŀ������ˣ�
    %io:format("H=~p~n", [H]),
    Soldier = baiqi_tools:get_soldier_by_position(H),
    
    if 
        Soldier == none ->
            Ret = false;
        
        %% ���˾ͼ������Ŀ����Ƿ��������Ҫȥ�ĸ���
        %% ��Чʱ��Ҫ�����ǵ�ʱ����
        true ->
            %io:format("des=~p, penemy=~p~n", [{Xt, Yt}, Soldier#soldier.position]),
            if
                TimeFuture =< Soldier#soldier.act_effect_time ->
                    {X, Y} = get_future_pos(Soldier#soldier.action,
                                            Soldier#soldier.facing,
                                            Soldier#soldier.position),
                    if
                        {X, Y} == {Xt, Yt} -> Ret = true;
                        true -> Ret = false
                    end;
                    
                true ->
                    Ret = false
            end
    end,
    
    if
        Ret == true -> check_future_pos({Xt, Yt}, TimeFuture, T, [Soldier#soldier.facing|Result]);
        Ret == false -> check_future_pos({Xt, Yt}, TimeFuture, T, Result)
    end.
    

%% �������Ƿ�����
%% ���� true
%% ���� false
pos_is_used({X, Y}) ->
    Soldier = baiqi_tools:get_soldier_by_position({X, Y}),

    Soldier /= none.

%% �õ�{Xo, Yo}Ŀ��{Xt, Yt}��Χ������3������
get_around_pos({Xo, Yo}, {Xt, Yt}) ->
    East    = {Xt+1, Yt},
    North   = {Xt, Yt-1},
    West    = {Xt-1, Yt},
    South   = {Xt, Yt+1},
    L = [East, North, West, South],
    %io:format("round=~p~n", [L]),
    lists:filter(
		fun(Pos) ->
			{Xo, Yo} /= Pos
		end,
		L).

%% �õ�ǰ���һ������λ��
get_ahead_pos(Facing, X, Y) ->
    case Facing of
        "east"  -> {X+1, Y};
        "north" -> {X, Y-1};
        "west"  -> {X-1, Y};
        "south" -> {X, Y+1};
        _Else   -> {X, Y}
    end.

%% �õ������һ������λ��
get_behind_pos(Facing, X, Y) ->
    case Facing of
        "east"  ->
            if
                X > 0   -> {X-1, Y};
                true    -> {X, Y}
            end;
        "west"  ->
            if
                X < 14  -> {X+1, Y};
                true    -> {X, Y}
            end;

        "south" ->
            if
                Y < 14  -> {X, Y+1};
                true    -> {X, Y}
            end;

        "north" ->
            if
                Y > 0   -> {X, Y-1};
                true    -> {X, Y}
            end
    end.

%% ���ƻ�ִ���������ʱ�޶��ƻ�
revise_plan(Soldier, Mission_queue, Cmd_queue) ->
    %% �õ�սʿ��ǰλ��
    Soldier_we = baiqi_tools:get_soldier_by_id_side(Soldier#soldier.id),
    
    %% �õ�Ŀ�굱ǰλ��
    Key = ets:first(Mission_queue),
    if
        Key == '$end_of_table' ->
            Soldier_enemy = Soldier_we;
        true ->
            Soldier_info = lists:nth(1, ets:select(Mission_queue, [{#soldier_mission{id = Key, priority='_', act='_', target='_'}, [], ['$_']}])),
            Soldier_enemy = Soldier_info#soldier_mission.target
    end,

    %% �ж϶����н�Ҫִ�е������Ƿ��ܳɹ������򻻸�·��
    Cmd_we = view_next_cmd(Mission_queue, Cmd_queue),
    
    case check_cmd(Soldier, Cmd_we, Mission_queue, Cmd_queue) of
        %% �����������߶��ˣ�����·
        'detour' ->
            modify_soldier_cmd_queue("attack", Cmd_queue);
            %Cmd_next = view_next_cmd(Mission_queue, Cmd_queue),
            %io:format("Cmd_next=~p~n", [Cmd_next]);
            
        %% ���˵��ǲ�������棬�򹥻�
        'attack' ->
            modify_soldier_cmd_queue("attack", Cmd_queue);
            %Cmd_next = view_next_cmd(Mission_queue, Cmd_queue),
            %io:format("Cmd_next=~p~n", [Cmd_next]);
            
        %% ����ʱû�ˣ�����������
        'search' ->
            re_gen_plan(Soldier_we, Soldier_enemy, Cmd_queue);
            
        %% û�˼���ԭ��
        'none' ->
            re_gen_plan(Soldier_we, Soldier_enemy, Cmd_queue)
    end.
    
%% �����趨·��
re_gen_plan(Soldier, Soldier_enemy, Cmd_queue) ->
    ets:delete_all_objects(Cmd_queue),
    gen_plan(Soldier, Soldier_enemy, Cmd_queue).
    
%% �޸�������е�����һ��
modify_soldier_cmd_queue(Cmd, Cmd_queue) ->
    Key = ets:first(Cmd_queue),
    %io:format("Key = ~p, Cmd = ~p~n", [Key, Cmd]),
    if
        Key == '$end_of_table' ->
            Soldier_cmd = #soldier_cmd{
                                id          = 0,
                                mission     = 0,
                                name        = Cmd
                            },
            ets:insert(Cmd_queue, Soldier_cmd);
            
        true ->
            ets:update_element(Cmd_queue, Key, [{4, Cmd}])
            %K = ets:first(Cmd_queue),
            %C = lists:nth(1, ets:select(Cmd_queue, [{#soldier_cmd{id = Key, mission='_', name='_'}, [], ['$_']}])),
            %io:format("Key2 = ~p, Cmd2 = ~p~n", [K, C])
    end.


