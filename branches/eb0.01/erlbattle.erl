-module(erlbattle).
-export([start/0,timer/3]).

%% ս����ʼ����������
start() ->
    io:format("Server Starting ....~n", []),
	
    %%  TODO: �����������ӵĳ�ʼ״̬
	io:format("Army matching into the battle fileds....~n", []),
	
	%%  TODO: �����Ҫ�Ǻ���������ÿ̨�������ܹ�����ͬ�Ľ�����е�����
	%%  io:format("Testing Computer Speed....~n", [])
	Sleep = 10,

	%% ����һ����ʱ��, ��Ϊս������
	spawn(erlbattle, timer, [self(),1,Sleep]),

	%% ��������ָ����У� ����������ֻ���ɸ��Կ���
	BlueQueue = ets:new(blueQueue, []),
	RedQueue = ets:new(redQueue, []),
	
	%% �����췽�������ľ��߳���
	%% TODO:  Ϊ�˱���ĳһ��ͨ������Ϣ��Ӱ��Է��� δ��Ҫ�ж�����ͨѶ������ÿ������Ϣ
	io:format("Command Please, Generel....~n", []),
	BlueSide = spawn(feardFarmers, start, [self(), "Blue"]),
	RedSide = spawn(englandArmy, start, [self(), "Red"]),
	

	%% ��ʼս��ѭ��
	run(BlueSide, RedSide,BlueQueue, RedQueue).
		

%% ս���߼�������	
run(BlueSide, RedSide,BlueQueue, RedQueue) ->
	
	receive 
		finish ->
			BlueSide!finish,
			RedSide!finish,
			io:format("Sun goes down, battle finished!~n", []),
			%% ���ս�����
			io:format("The winner is blue army ....~n", []);			
		{time, Time} ->
				%% TODO ս���߼�
				%% do something
				io:format("Time: ~p s ....~n", [Time]),
				run(BlueSide, RedSide,BlueQueue, RedQueue);
		{command,Command,Warrior,Time} ->
				%% Todo ������Ϣ
				io:format("~p warrior want ~p at ~p ~n", [Warrior, Command, Time]),
				
				run(BlueSide, RedSide,BlueQueue, RedQueue)
	end.

%% Todo: Sleep С����,��Ϣ���ɺ���
timer(Pid, Time,Sleep) -> 
	
	sleep(Sleep),
	
	%% ս��������еĴ��� 
	MaxTurn = 5,
	if 
		Time == MaxTurn ->
			Pid!finish;
		Time < MaxTurn ->
			Pid !{time, Time},
			timer(Pid, Time+1,Sleep)
	end.

	
%% Sleep ���ߺ���
sleep(Sleep) ->
	receive
	
	after Sleep -> true
    
	end.
