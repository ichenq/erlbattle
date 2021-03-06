-module(tools).
-export([sleep/1,getLongDate/0,keyfind/3,for/3]).

%% Sleep 工具函数
sleep(Sleep) ->
	receive
	
	after Sleep -> true
    
	end.
	
getLongDate() ->
	{MegaSecs, Secs, MicroSecs} = now(),
	Seed = 1000 * 1000,
	(MegaSecs * Seed + Secs) *Seed + MicroSecs.
	
%% 兼容代码
keyfind(Key, N, List) ->
	
	case lists:keysearch(Key, N, List) of
		
		false -> false;
		{_Val, Result} -> Result;
		_ELSE -> false
	end.

%% 创造一个for 循环算法
for(I, I, Fun) -> Fun(I);	
for(I, N, Fun) ->
	Fun(I),
	for(I+1, N, Fun).