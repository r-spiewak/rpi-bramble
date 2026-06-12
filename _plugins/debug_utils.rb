###################################################
# Debug Utilities Mixin
###################################################
#  
# Include this in other Ruby classes as a mixin with 
# `include DebugUtils`
# For example:
# ```
# class InheritingClass
#     include DebugUtils
# ```
# 
# To override the class method and enable all debug prints for the
# inheriting class, set in the inheriting class
# ```
# def self.debug_mode
#     true
# end
# ```
# For example:
# ```
# class InheritingClass
#     include DebugUtils
#     def self.debug_mode
#         true
#     end
# ```
# 
# To override just a specific place in a method in an inheriting class,
# wrap that place in between the two lines:
# ````
# DebugUtils.set_debug_mode(true)
# DebugUtils.set_debug_mode(false)
# ````
# For example:
# ```
# class InheritingClass
#     include DebugUtils
#     def a_method()
#         DebugUtils.set_debug_mode(true)
#         self.debug_print("SidebarGeneratorTag", "a_method", "This will print!")
#         DebugUtils.set_debug_mode(false)
# ```

module DebugUtils
    
    # Colored Text
    COLORS = {
        "WHITE" => "\e[0m",
        "RED" => "\e[31m",
        "GREEN" => "\e[32m",
        "BLUE" => "\e[34m",
        "YELLOW" => "\e[33m"
    }

    # Text Color States
    COLORS["DEBUG"] = COLORS["BLUE"]
    COLORS["NORMAL"] = COLORS["WHITE"]
    COLORS["ERROR"] = COLORS["RED"]
    COLORS["WARNING"] = COLORS["YELLOW"]

    # Use a thread-local variable for debugging control
    # This is the correct way to manage state for complex processes.
    def self.set_debug_mode(state)
        Thread.current[:debug_mode] = state
    end

    # DEBUG = false
    # if DEBUG
    #     require 'json'
    # end

    def self.included(base)
        # The 'included' hook allows a module to declare class-level attributes
        base.extend(ClassMethods)
    end
    module ClassMethods
        # Class-level attribute
        def debug_mode
            false
        end
    end

    # def self.debug_print(class_name, method, message, *args)
    def debug_print(class_name, method, message, *args)
        # if DEBUG
        if Thread.current[:debug_mode] == true or self.class.debug_mode == true
            # Use a specific tag for easier searching later
            puts "#{COLORS['DEBUG']}--- [DEBUG][#{class_name}][#{method}] ---#{COLORS['NORMAL']} #{message} #{args.join(' ')}"
        end
    end

    # def self.debug_p(obj)
    def debug_p(obj)
        # if DEBUG
        if Thread.current[:debug_mode] == true or self.class.debug_mode == true
            # Use a specific tag for easier searching later
            p obj
        end
    end

    # def self.debug_json(class_name, method, message, obj)
    def debug_json(class_name, method, message, obj)
        # if DEBUG
        if Thread.current[:debug_mode] == true or self.class.debug_mode == true
            require 'json'
            json_str = JSON.pretty_generate(obj, indent: "    ")
            puts "#{COLORS['DEBUG']}--- [DEBUG][#{class_name}][#{method}] ---#{COLORS['NORMAL']} #{message} #{json_str}"
        end
    end
end
