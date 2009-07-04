-module(erlbattle).
-export([start/0]).
-include("schema.hrl").
-include("test.hrl").

%% 战场初始化启动程序
start() ->
    io:format("Server Starting ....~n", []),
	
    %% 创建两方部队的初始状态
	io:format("Army matching into the battle fileds....~n", []),
	battlefield:create(),
	
	%%  TODO: 这段主要是后面用于让每台机器都能够以相同的结果运行的作用
	%%  io:format("Testing Computer Speed....~n", [])
	Sleep = 10,

	%% 启动一个计时器, 作为战场节拍
	Timer = spawn(worldclock, start, [self(),0,Sleep]),

	%% 创建两个指令队列， 这两个队列只能由各自看到
	BlueQueue = ets:new(blueQueue, [{keypos, #command.warrior_id}]),
	RedQueue = ets:new(redQueue, [{keypos, #command.warrior_id}]),
	
	%% 启动红方和蓝方的决策程序
	%% TODO:  为了避免某一方通过狂发消息，影响对方， 未来要有独立的通讯程序负责每方的信息
	io:format("Command Please, Generel....~n", []),
	BlueSide = spawn(feardFarmers, start, [self(), "Blue"]),
	RedSide = spawn(englandArmy, start, [self(), "Red"]),
	

	%% 开始战场循环
	run(Timer, BlueSide, RedSide,BlueQueue, RedQueue).
		

%% 战场逻辑主程序
run(Timer, BlueSide, RedSide, BlueQueue, RedQueue) ->
	receive 
		
		{Timer, finish} ->
				BlueSide!finish,
				RedSide!finish,
				io:format("Sun goes down, battle finished!~n", []),
				%% 输出战斗结果
				io:format("The winner is blue army ....~n", []),
				ets:delete(battle_field);		
				
		{Timer, time, Time} ->
				%% TODO 战场逻辑
				%% do something
				io:format("Time: ~p s ....~n", [Time]),
				
				%% 计算所有生效的动作
				takeAction(Time),
				
				%% 从队列拿到处于wait 状态的战士的新的动作，并将该指令从队列中删除
				%% do something
				
				%% 等待下一个节拍
				run(Timer, BlueSide, RedSide,BlueQueue, RedQueue);

		{Side, command,Command,Warrior,Time} ->
				%% 生成一个command 记录
				CmdRec = #command{
						warrior_id = Warrior,
						command_name = Command,
						execute_time = Time},
				case Side of
					%% 蓝方发来的命令
					BlueSide ->
						io:format("BlueSide: warrior ~p want ~p at ~p ~n", [Warrior, Command, Time]),
						ets:insert(BlueQueue, CmdRec),
						?debug_print(true, ets:tab2list(BlueQueue));
					%% 红方发来的命令
					RedSide ->
						io:format("RedSide: ~p warrior want ~p at ~p ~n", [Warrior, Command, Time]),
						ets:insert(RedQueue, CmdRec),
						?debug_print(true, ets:tab2list(RedQueue));
					%% 不知道是那一方发来的命令
					_ ->
						io:format("UnknowSide: ~p warrior want ~p at ~p ~n", [Warrior, Command, Time])
				end,
				run(Timer, BlueSide, RedSide,BlueQueue, RedQueue)
	end.

	
%% 计算当前节拍，所有需要生效的动作
takeAction(Time) ->
	
	%% 首先从战场状态表中取出本节拍生效的动作，取其中一个开始处理
	case getActingWorriar(Time) of
	
		{Worriar} ->
				
			%% 处理Worria 的动作，更新世界表，如果有人被杀，就将该人从世界中移走
			act(Worriar),
			
			%% 再读下一个需要执行的战士
			takeAction(Time);
		_ ->
			none
	end.
			
	
	
%% 执行一个战士的动作
act(Worriar) ->

	%% do something
	Worriar.
	
%% 获得一个当前节拍需要执行任务的战士信息
getActingWorriar(Time) ->

	%% TODO: 根据sequence 取，以及随机挑选红方，蓝方谁先动
	Pattern=#soldier{
				id='_',
				position={'_','_'},
				hp='_',
				direction='_',
				action='_',
				act_effect_time = Time
			},
	case ets:match_object(battle_field,Pattern) of
		[Soldier|_] ->
			Soldier;
		[]->
			none
	end.
	
	
	
	
	
	

