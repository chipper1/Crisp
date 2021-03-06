require "./expr"
require "./error"

module Crisp
  class Env
    property data

    def initialize(@outer : Env? = nil)
      @data = {} of String => Crisp::Expr
    end

    def initialize(@outer, binds, exprs : Array(Crisp::Expr))
      @data = {} of String => Crisp::Expr

      Crisp.eval_error "binds must be list or vector" unless binds.is_a? Array

      # Note:
      # Array#zip() can't be used because overload resolution failed
      (0...binds.size).each do |idx|
        sym = binds[idx].unwrap
        Crisp.eval_error "bind name must be symbol" unless sym.is_a? Crisp::Symbol

        if sym.str == "&"
          Crisp.eval_error "missing variable parameter name" if binds.size == idx
          next_param = binds[idx + 1].unwrap
          Crisp.eval_error "bind name must be symbol" unless next_param.is_a? Crisp::Symbol
          var_args = Crisp::List.new
          exprs[idx..-1].each { |e| var_args << e } if idx < exprs.size
          @data[next_param.str] = Crisp::Expr.new var_args
          break
        end

        @data[sym.str] = exprs[idx]
      end
    end

    def dump
      puts "ENV BEGIN".colorize.red
      @data.each do |k, v|
        puts "  #{k} -> #{print(v)}".colorize.red
      end
      puts "ENV END".colorize.red
    end

    def set(key, value)
      @data[key] = value
    end

    def find(key)
      return self if @data.has_key? key

      if o = @outer
        o.find key
      else
        nil
      end
    end

    def get(key)
      e = find key
      Crisp.eval_error "'#{key}' not found" unless e
      e.data[key]
    end
  end
end
