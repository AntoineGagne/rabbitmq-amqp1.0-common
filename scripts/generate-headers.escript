#! /usr/bin/env escript
%% -*- erlang -*-

-define(REPOSITORY, "https://github.com/rabbitmq/rabbitmq-codegen.git").
-define(DEPENDENCY_DIRECTORY, "deps").
-define(SOURCE_DIRECTORY, "src").
-define(INCLUDE_DIRECTORY,"include").
-define(CODE_GENERATION_DIRECTORY, filename:join(?DEPENDENCY_DIRECTORY, "rabbitmq_codegen")).
-define(SPECIFICATION_DIRECTORY, "amqp-1.0").
-define(SPECIFICATION_FILES, [
                              "messaging.xml",
                              "security.xml",
                              "transport.xml",
                              "transactions.xml"
                             ]).

-spec clone_repository(Repository :: string(), Output :: string()) -> string().
clone_repository(Repository, Output) ->
    Raw = lists:join($ , ["git", "clone", Repository, Output]),
    Command = unicode:characters_to_list(Raw),
    os:cmd(Command).

-spec specification_files() -> string().
specification_files() ->
    SpecificationDirectory = filename:join(?CODE_GENERATION_DIRECTORY, ?SPECIFICATION_DIRECTORY),
    RawSpecificationFiles = [filename:join(SpecificationDirectory, F) || F <- ?SPECIFICATION_FILES],
    Joined = lists:join($ , RawSpecificationFiles),
    unicode:characters_to_list(Joined).

-spec generate(Output :: string(), Type :: string()) -> ok | {error, term()}.
generate(Output, Type) ->
    SpecificationFiles = specification_files(),
    Raw = lists:join($ , ["python", "codegen.py", Type, SpecificationFiles]),
    Command = unicode:characters_to_list(Raw),
    Result = os:cmd(Command),
    file:write_file(Output, Result).

-spec main([term()]) -> ok.
main(_Arguments) ->
    HeaderFile = filename:join(?INCLUDE_DIRECTORY, "amqp10_framing.hrl"),
    SourceFile = filename:join(?SOURCE_DIRECTORY, "amqp10_framing0.erl"),
    ok = lists:foreach(fun (D) -> ok = filelib:ensure_dir(D) end, [HeaderFile, SourceFile]),
    clone_repository(?REPOSITORY, ?CODE_GENERATION_DIRECTORY),
    true = os:putenv("PYTHONPATH", ?CODE_GENERATION_DIRECTORY),
    ok = generate(HeaderFile, "hrl"),
    ok = generate(SourceFile, "erl").
