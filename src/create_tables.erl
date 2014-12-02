-module(create_tables).

-export([init_tables/0,
         insert_user/3,
         insert_project/2]).

-include_lib("eunit/include/eunit.hrl").
-include_lib("stdlib/include/qlc.hrl").

-record(user, {id,
               name}).

-record(project, {title,
                  description}).

-record(contributor, {user_id,
                      title}).

-define(COLUMNS(RecordName), {attributes, record_info(fields, RecordName)}).

%%--------------------------------------------------------------------
%% API
%%--------------------------------------------------------------------

%% @doc Init tables
%% NOTE: Before running that `mnesia:start()` need to be called.
init_tables() ->
    {atomic, ok} = mnesia:create_table(user, [?COLUMNS(user)]),
    {atomic, ok} = mnesia:create_table(project, [?COLUMNS(project)]),
    {atomic, ok} = mnesia:create_table(contributor,
                                      [{type, bag}, ?COLUMNS(contributor)]).

insert_user(Id, Name, ProjectTitles) when ProjectTitles =/= [] ->
    Fun = fun() ->
                  mnesia:write(#user{id = Id, name = Name}),
                  lists:foreach(
                    fun(Title) ->
                            [#project{title = Title}] = mnesia:read(project,
                                                                    Title),
                            mnesia:write(#contributor{user_id = Id,
                                                      title = Title})
                    end, ProjectTitles)
          end,
    mnesia:transaction(Fun).

insert_project(Title, Description) ->
    mnesia:dirty_write(#project{title = Title, description = Description}).

%%--------------------------------------------------------------------
%% Tests
%%--------------------------------------------------------------------

tables_test_() ->
    {setup,
     fun setup/0,
     fun teardown/1,
     [fun test1/0,
      fun test2/0,
      fun test3/0,
      fun test4/0,
      fun test5/0,
      fun test6/0,
      fun test7/0]}.

setup() ->
    mnesia:start(),
    init_tables(),
    %% dbg:tracer(),
    %% dbg:p(all,c),
    %% dbg:tpl(mnesia, write, 1, x),
    [insert_project(T, D)
     || {T, D} <- [{szymon_girlfriend, "being szymon's prettiest girl"},
                   {alice_boyfriend, "being alice's strongest man"},
                   {mnesia_freak, "writing sutpid mnesia tests"}]],
    [insert_user(I, N, P) || {I, N, P} <- [{1, szymon, [alice_boyfriend,
                                                        mnesia_freak]},
                                           {2, alice, [szymon_girlfriend]}]].

teardown(_) ->
    [mnesia:delete_table(T) || T <- [user, project, contributor]].

test1() ->
    ?assertMatch([#contributor{user_id = 2, title = szymon_girlfriend}],
                 mnesia:dirty_read(contributor, 2)).

test2() ->
    Match = [#contributor{user_id = 1, title = T} || T <- [alice_boyfriend,
                                                           mnesia_freak]],
    ?assertMatch(Match,
                 mnesia:dirty_match_object(#contributor{user_id = 1, _ = '_'})).

test3() ->
    MatchHead = #contributor{user_id = 1, title = '$1'},
    MatchSpec = [{MatchHead, _Guard = [], _Result = ['$1']}],
    ?assertMatch([alice_boyfriend, mnesia_freak],
                 mnesia:dirty_select(contributor, MatchSpec)).

test4() ->
    MatchHead = #contributor{user_id = 1, title = '$1'},
    MatchSpec = [{MatchHead, _Guard = [], _Result = [{is_atom, '$1'}]}],
    ?assertMatch([true, true], mnesia:dirty_select(contributor, MatchSpec)).

test5() ->
    MatchHead = #contributor{user_id = '$2', title = '$1'},
    Guard = [{'==', '$1', mnesia_freak}],
    MatchSpec = [{MatchHead, Guard, _Result = ['$$']}],
    ?assertMatch([[mnesia_freak, 1]],
                 mnesia:dirty_select(contributor, MatchSpec)).

test6() ->
    MatchHead = #contributor{user_id = 2, _ = '_'},
    MatchSpec = [{MatchHead, _Guard = [], _Result = ['$_']}],
    ?assertMatch([#contributor{user_id = 2, title = szymon_girlfriend}],
                 mnesia:dirty_select(contributor, MatchSpec)).

test7() ->
    Fun = fun() ->
                  Table = mnesia:table(contributor),
                  [UserId] = mnesia:dirty_select(
                               user,
                               [{#user{name = szymon, id = '$1'}, [], ['$1']}]),
                  QueryHandle = qlc:q([P#contributor.title
                                       || P <- Table,
                                          P#contributor.user_id =:= UserId]),
                  qlc:eval(QueryHandle)
          end,
    ?assertMatch({atomic, [alice_boyfriend, mnesia_freak]},
                 mnesia:transaction(Fun)).











