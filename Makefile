.PHONY: run compile clean

mnesia_db = "/tmp/mnesia_store"

run: compile
	erl -mnesia dir '$(mnesia_db)' -sname mnesia_node -pa ebin/

test: compile
	erl -mnesia dir '$(mnesia_db)' -sname mnesia_node -pa ebin/ \
		-s eunit test create_tables -s init stop

compile: compile
	erlc -o ebin/ src/create_tables.erl

clean:
	rm -rf ebin/*.beam $(mnesia_db)
