module Ruboty
  module Handlers
    class ScopedAlias < Base
      NAMESPACE = "scoped_alias"

      on(
        /scoped alias (?<original>.+?) -> (?<alias>.+)\z/m,
        description: "Create scoped alias message",
        name: "create",
      )

      on(
        /list scoped alias\z/,
        description: "List scoped alias",
        name: "list",
      )

      on(
        /delete scoped alias (?<alias>.+)\z/m,
        description: "Delete scoped alias",
        name: "delete",
      )

      on(
        //,
        description: "Resolve scoped alias if registered",
        name: "resolve",
        hidden: true,
      )

      def create(message)
        scope = message[:from]
        from = message[:original]
        to = message[:alias]
        table[scope] ||= {}
        table[scope][from] = to
        message.reply("Registered alias: #{from} -> #{to}")
      end

      def delete(message)
        scope = message[:from]
        table[scope] ||= {}
        if table[scope].delete(message[:alias])
          message.reply("Deleted")
        else
          message.reply("Not found")
        end
      end

      def list(message)
        message.reply(aliases(message[:from]), code: true)
      end

      def resolve(message)
        scope = message[:from]
        table[scope] ||= {}
        from = message.body.gsub(prefix, "")
        if aliased = table[scope][from]
          robot.receive(
            message.original.merge(
              body: "#{message.body[prefix]}#{aliased}"
            )
          )
          true
        else
          false
        end
      end

      private

      def table
        robot.brain.data[NAMESPACE] ||= {}
      end

      def aliases(scope)
        scoped_table = table[scope] || {}
        if scoped_table.empty?
          "No alias registered"
        else
          scoped_table.map {|from, to| "#{from} -> #{to}" }.join("\n")
        end
      end

      def prefix
        Ruboty::Action.prefix_pattern(robot.name)
      end
    end
  end
end
