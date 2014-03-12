module ActionDispatch
  module Routing
    class Mapper

      # Facilitates matching a named route similar to the set of routes
      # produced by the resources method
      #
      # You should either invoke this as 
      #
      #   simple_named_route 'controller', 'action', route_options
      # 
      # or
      #
      #   simple_named_route 'action', route_options
      #
      # "route_options" is optional
      #
      # The latter will use @scope[:controller] - which is useful for 
      # defining routes using the controller :blah { route; route; route;}
      # syntax

      def simple_named_route(*args)
        case args.length
        when 3
          controller = args[0].to_s
          action = args[1].to_s
          route_options = args[2]
        when 2 
          # could be controller,action or action,route_options
          if(args[1].is_a?(Hash))
            controller = @scope[:controller]
            action = args[0].to_s
            route_options = args[1]
          else # assumes string or symbol
            controller = args[0].to_s
            action = args[1].to_s
            route_options = {}
          end
        when 1
          controller = @scope[:controller]
          action = args[0].to_s
          route_options = {}          
        else
          rails ArgumentError, "invalid arguments to named_route"
        end 

        match_options = {to: "#{controller}##{action}", as: "#{controller}_#{action}", via: [:get]}
        match_options.merge!(route_options)

        if(action == 'index')
          path = "#{controller}"
        else
          path = "#{controller}/#{action}"
        end
        match(path, match_options)
      end

    end
  end
end