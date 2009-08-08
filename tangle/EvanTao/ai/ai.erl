-module(ai).
-include("schema.hrl").

-compile(export_all).

-define(MaxRow, 14).
-define(MaxCol, 14).

%% TODO
%% �������̣��������߽硢���ˡ����γɱ��ȵ�
%% ������ets,̫�������ɴ�������:-P

%% �����������̹�������ʹ��ets��Ȼ����µ����̡�
%% ������Ҫ���㷨�������ets��

start() ->
    Begin = {1, 3},
    End = {5, 0},
    
    {A1,A2,A3} = now(),
    io:format("StartTime = ~p~n", [{A1,A2,A3}]),
    
    %% ����׷���㷨
    %Path = build_path_to_target(Begin, End),
    
    %% A*�㷨
    Path = astar(Begin, End),
    
    {B1,B2,B3} = now(),
    io:format("StopTime = ~p~n", [{B1,B2,B3}]),
    io:format("From ~p to ~p~nPath=~p~nTime cost: ~pus~n", [Begin, End, Path, B3 - A3]),
    
    ok.

%% == Besenham�㷨 ==
build_path_to_target(Begin, End) when is_tuple(Begin) andalso is_tuple(End) ->
    {Row, Col} = Begin,
    {EndRow, EndCol} = End,
    
    if
        EndRow - Row < 0 -> StepRow = -1;
        true -> StepRow = 1
    end,
    
    if
        EndCol - Col < 0 -> StepCol = -1;
        true -> StepCol = 1
    end,
    
    DeltaRow = abs((EndRow - Row)*2),
    DeltaCol = abs((EndCol - Col)*2),
    
    if
        DeltaCol > DeltaRow ->
            Path = through_col(EndCol, Row, Col, StepRow, StepCol, 0, DeltaRow*2-DeltaCol, DeltaRow, DeltaCol);
        true ->
            Path = through_row(EndRow, Row, Col, StepRow, StepCol, 0, DeltaCol*2-DeltaRow, DeltaRow, DeltaCol)
    end,
    
    lists:reverse(Path).

through_col(EndCol, NextRow, NextCol, StepRow, StepCol, CurrentStep, Fraction, DeltaRow, DeltaCol) ->
    through_col([], EndCol-NextCol, EndCol, NextRow, NextCol, StepRow, StepCol, CurrentStep, Fraction, DeltaRow, DeltaCol).
    
through_col(Path, 0, _EndCol, _NextRow, _NextCol, _StepRow, _StepCol, _CurrentStep, _Fraction, _DeltaRow, _DeltaCol) ->
    Path;
through_col(Path, EndWhileCondition, EndCol, NextRow, NextCol, StepRow, StepCol, CurrentStep, Fraction, DeltaRow, DeltaCol) ->
    if
        Fraction >= 0 ->
            NextRow2 = NextRow + StepRow,
            NextCol2 = NextCol + StepCol,
            NextPath = {CurrentStep, {NextRow2, NextCol2}},
            Fraction2 = Fraction - DeltaCol + DeltaRow;
        true ->
            NextRow2 = NextRow,
            NextCol2 = NextCol + StepCol,
            NextPath = {CurrentStep, {NextRow2, NextCol2}},
            Fraction2 = Fraction + DeltaRow
    end,
    
    through_col([NextPath|Path], EndCol-NextCol2, EndCol, NextRow2, NextCol2, StepRow, StepCol, CurrentStep+1, Fraction2, DeltaRow, DeltaCol).

through_row(EndRow, NextRow, NextCol, StepRow, StepCol, CurrentStep, Fraction, DeltaRow, DeltaCol) ->
    through_row([], EndRow-NextRow, EndRow, NextRow, NextCol, StepRow, StepCol, CurrentStep, Fraction, DeltaRow, DeltaCol).
    
through_row(Path, 0, _EndRow, _NextRow, _NextCol, _StepRow, _StepCol, _CurrentStep, _Fraction, _DeltaRow, _DeltaCol) ->
    Path;
through_row(Path, EndWhileCondition, EndRow, NextRow, NextCol, StepRow, StepCol, CurrentStep, Fraction, DeltaRow, DeltaCol) ->
    if
        Fraction >= 0 ->
            NextRow2 = NextRow + StepRow,
            NextCol2 = NextCol + StepCol,
            NextPath = {CurrentStep, {NextRow2, NextCol2}},
            Fraction2 = Fraction - DeltaRow + DeltaCol;
        true ->
            NextRow2 = NextRow + StepRow,
            NextCol2 = NextCol,
            NextPath = {CurrentStep, {NextRow2, NextCol2}},
            Fraction2 = Fraction + DeltaCol
    end,
    
    through_row([NextPath|Path], EndRow-NextRow2, EndRow, NextRow2, NextCol2, StepRow, StepCol, CurrentStep+1, Fraction2, DeltaRow, DeltaCol).

%% == A*�㷨 ==

%% �ڵ������={X, Y, ����}�����ڵ����꣬�ɱ�
-record(tile, {pos, parent, cost}).

astar(PosStart, PosGoal) when is_tuple(PosStart) andalso is_tuple(PosGoal) ->
    TileStart = #tile{pos = PosStart, parent = null, cost = 0},
    TileGoal = #tile{pos = PosGoal, cost = 0},
    
    %% �Ȱ���ʼ�ڵ���� open list
    %% astar(open list �������ڵ㣬�ս�������closed list)
    astar([TileStart], TileGoal, PosStart==PosGoal, []).

astar(OpenList, TileGoal, true, ClosedList) ->
    %% ��򵥵�����£����û��ݡ�
    %lists:reverse(ClosedList);
    
    %% ���򣬾�Ҫʹ�û��ݵ����ķ����ҳ�·����
    %% ����ʱ�����ð�list���򣬲���Ҫreverse�ˡ�
    TilesList = [OpenList|ClosedList],
    Tile = lists:keyfind(TileGoal#tile.pos, 2, TilesList),
    get_path(Tile, TilesList, []);
astar([], _TileGoal, _EndCondition, _ClosedList) ->
    [];    
astar(OpenList, TileGoal, false, ClosedList) ->
    %% ��ǰ�ڵ� = open list �гɱ���͵Ľڵ�
    TileCurrent = get_lowest_cost_tile(OpenList),
    
    %% �ѵ�ǰ�ڵ�Ž�closed list
    OpenList2 = remove_lowest_cost_tile(OpenList, TileCurrent),
    ClosedList2 = [TileCurrent | ClosedList],
    
    %% ��鵱ǰ�ڵ��ÿ�����ڽڵ�
    OpenList3 = check_around_tile(TileCurrent, OpenList2, ClosedList2, TileGoal),
    
    %% ��ǰ�ڵ� = Ŀ��ڵ㣬����ɲ���
    IsGoal = is_goal(TileCurrent, TileGoal),

    astar(OpenList3, TileGoal, IsGoal, ClosedList2).

%% ��Ŀ�꿪ʼ�����ݵ���ʼλ�ã�����·����
get_path(false, _TilesList, Path) ->
    Path;
get_path(Tile, TilesList, Path) ->
    TileParent = lists:keyfind(Tile#tile.parent, 2, TilesList),
    get_path(TileParent, TilesList, [Tile|Path]).

%% Ѱ��open list�гɱ���͵Ľڵ㣬�����ж��
get_lowest_cost_tile([Tile|OpenList]) ->
    %% ���ѡ��
    TileMinCost = get_lowest_cost_tile(OpenList, Tile),
    TileMinCosts = lists:filter(
    fun(T) ->
        T#tile.cost == TileMinCost#tile.cost
    end,
    [Tile|OpenList]),
    %io:format("TileMinCosts=~p~n", [TileMinCosts]),
    lists:nth(srandom(length(TileMinCosts)), TileMinCosts).

    %% Ĭ��ѡ��
    %get_lowest_cost_tile(OpenList, Tile).

get_lowest_cost_tile([], Min) ->
    Min;
get_lowest_cost_tile([Tile|OpenList], Min) when Tile#tile.cost < Min#tile.cost ->
    get_lowest_cost_tile(OpenList, Tile);
get_lowest_cost_tile([Tile|OpenList], Min)  ->
    get_lowest_cost_tile(OpenList, Min).

%% ɾ��open list�гɱ���͵Ľڵ�
remove_lowest_cost_tile(OpenList, TileCurrent) ->
    lists:delete(TileCurrent, OpenList).
    
%% ���һ���ڵ���Χ�������ڵ�
check_around_tile(Tile, OpenList, ClosedList, TileGoal) when is_record(Tile, tile) ->
    AroundTiles = get_around_tile(Tile),
    check_around_tiles(AroundTiles, OpenList, ClosedList, TileGoal).

%% �õ�һ���ڵ���Χ�������ڵ�
%% ��׼ש�黷��������Χ8���ڵ�
%% ������EB�У���Ϊֱ�����ڵ�4������Ϊ�ƶ�����ֻ����ֱ�ߡ�
%% �����ŵ�ʵ���᣿
get_around_tile(Tile) ->
    {X, Y} = Tile#tile.pos,
    
    if
        X+1 < 14 -> AroundTiles =[#tile{pos = {X+1, Y}, parent = Tile#tile.pos}];
        true -> AroundTiles = []
    end,
    if
        Y+1 < 14 -> AroundTiles2 = [#tile{pos = {X, Y+1}, parent = Tile#tile.pos}|AroundTiles];
        true -> AroundTiles2 = AroundTiles
    end,
    if
        X-1 > -1 -> AroundTiles3 = [#tile{pos = {X-1, Y}, parent = Tile#tile.pos}|AroundTiles2];
        true -> AroundTiles3 = AroundTiles2
    end,
    if
        Y-1 > -1 -> AroundTiles4 = [#tile{pos = {X, Y-1}, parent = Tile#tile.pos}|AroundTiles3];
        true -> AroundTiles4 = AroundTiles3
    end,
    AroundTiles4.
    
%% ���һ���ڵ���Χ��ÿ�����ڽڵ�
%% ÿ�����ڽڵ㣬�������open list����closed list�����ϰ��������open list������ɱ�
check_around_tiles([], OpenList, _ClosedList, _TileGoal) ->
    OpenList;
check_around_tiles([Tile|AroundTiles], OpenList, ClosedList, TileGoal) ->
    IsInOpenList = lists:keymember(Tile#tile.pos, 2, OpenList),
    IsInClosedList = lists:keymember(Tile#tile.pos, 2, ClosedList),
    IsBarrier = tile_is_barrier(Tile),
    if
        not IsInOpenList
        and not IsInClosedList
        and not IsBarrier ->
            %% ��ǰ�ڵ����ھӵĸ��ڵ�
            %TileCurrent = Tile#tile.parent,
            TileCurrent = lists:keyfind(Tile#tile.parent, 2, OpenList),
            
            if
                TileCurrent == false ->
                    TileCurrent2  = lists:keyfind(Tile#tile.parent, 2, ClosedList);
                true ->
                    TileCurrent2 = TileCurrent
            end,
            
            %% �����ھӽڵ�ĳɱ�
            %% ��ʼ�ڵ��б�־ʶ����˲��õ������ݽ���
            Cost = calc_cost(Tile, TileGoal, TileCurrent2, OpenList),
            
            Tile2 = Tile#tile{cost = Cost},
            OpenList2 = [Tile2|OpenList];
        true ->
            OpenList2 = OpenList
    end,
    check_around_tiles(AroundTiles, OpenList2, ClosedList, TileGoal).

%% ��鵱ǰ�ڵ��Ƿ���Ŀ��ڵ�
%% �ȼ������ TODO: ��鷽��
is_goal(TileCurrent, TileGoal) ->
    TileCurrent#tile.pos == TileGoal#tile.pos.
    
%% ����ڵ�ĳɱ�
%% �ƶ����ýڵ�ĳɱ�+�ýڵ��ƶ���Ŀ��ĳɱ�
%% TODO �ƶ�ʱ�ĳɱ�Ҫ���ǵ��ı䷽��Ļ��ѡ�
calc_cost(TileNeighbor, TileGoal, TileCurrent, OpenList) ->
    g_n(TileNeighbor, TileCurrent, OpenList) + h_n(TileNeighbor, TileGoal).

%% ���ھӵĳɱ�Ϊ��ʼ�ڵ㵽��ǰ�ڵ�ĳɱ�+��ǰ�ڵ��ƶ����ھӵĳɱ�
g_n(TileNeighbor, TileCurrent, OpenList) ->
    SumCost = sum_movement_cost(TileCurrent, OpenList),

    {Xn, Yn} = TileNeighbor#tile.pos,
    {Xc, Yc} = TileCurrent#tile.pos,
    MovementCost = movement_cost({Xn, Yn}, {Xc, Yc}),
    SumCost + MovementCost.

%% ��ʼ�ڵ㵽��ǰ�ڵ�ĳɱ�
sum_movement_cost(TileCurrent, OpenList) ->
    sum_movement_cost(TileCurrent, OpenList, 0).
    
sum_movement_cost(false, _OpenList, SumCost) ->
    SumCost;
sum_movement_cost(TileCurrent, OpenList, SumCost) ->
    PosCurrent = TileCurrent#tile.pos,
    TileParent = lists:keyfind(TileCurrent#tile.parent, 2, OpenList),
    if
        TileParent == false ->
            MovementCost = 0;
        true ->
            PosParent = TileParent#tile.pos,
            MovementCost = movement_cost(PosCurrent, PosParent)
    end,
    sum_movement_cost(TileParent, OpenList, SumCost+MovementCost).
    
%% ���ڵ�2���ڵ��ƶ��ɱ�
%% TODO ����ת��
movement_cost({Xo, Yo}, {Xt, Yt}) ->
    1.
    
%% ���ڵ�2���ڵ��ƶ��ɱ�
%movement_cost({Xo, Yo, Dir}, {Xt, Yt}) ->
%    case is_same_dir({Xo, Yo, Dir}, {Xt, Yt}) of
%        true ->
%            2;
%            
%        false ->
%            4
%    end.

%% ���ڵ�2�����ӵ����λ���Ƿ�һ��
is_same_dir({Xo, Yo, Dir}, {Xt, Yt}) ->
    case Dir of
        ?DirEast ->
            none;
            
        ?DirSouth ->
            none;
            
        ?DirWest ->
            none;
            
        ?DirNorth ->
            none
            
    end,
    true.

%% ����ʽ�������������㵱ǰ�ڵ㵽Ŀ��ڵ��ľ���
h_n(TileNeighbor, TileGoal) ->
    {Xn, Yn} = TileNeighbor#tile.pos,
    {Xg, Yg} = TileGoal#tile.pos,
    heuristic_ManhattanDistance({Xn, Yn}, {Xg, Yg}).
    
%% ����ʽ����-�����پ���
heuristic_ManhattanDistance({Xo, Yo}, {Xt, Yt}) ->
    abs(Xo-Xt) + abs(Yo-Yt).

%% �жϽڵ��Ƿ����ϰ���
tile_is_barrier(Tile) ->
    false.

%% �����
srandom(Value) ->
    {A, B, C} = now(),
	random:seed(A, B, C),
    random:uniform(Value).












