%% սʿ
%% {���, ����pid, ������, ���� = {����, ְ��, С��, �ϼ�}} {rank, post, group, superior}
-record(soldier_baiqi, {id, pid, proc_name, attr}).

%% սʿ������
%% id
%% priority ���ȼ���1��2��3����������ͬ�����
%% act ������move | attack
%% target Ŀ�꣺soldier
-record(soldier_mission, {id, priority, act, target}).

%% սʿ���������
%% id
%% mission ����ID
%% name ��������  = ��׼����
-record(soldier_cmd, {id, mission, name}).
