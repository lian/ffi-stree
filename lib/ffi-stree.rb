#
# ruby + libstree via ffi, interface without sized structs,
# inspired by github.com/tenderlove/stree
#
require 'ffi'

module FFI
module Stree
  extend FFI::Library
  # deps: use libstree v4.2 (4.3-pre2 gives unwanted results)
  ffi_lib 'libstree.so', '/opt/local/lib/libstree.dylib'

  # stringset
  attach_function :lst_stringset_new,  [], :pointer
  attach_function :lst_stringset_add,  [ :pointer, :pointer ], :void
  attach_function :lst_stringset_free, [ :pointer ], :void

  # stree string
  attach_function :lst_string_new,    [ :pointer, :uint, :uint ], :pointer
  attach_function :lst_string_free,   [ :pointer ], :void
  attach_function :lst_string_print,  [ :pointer ], :string

  # stree tree
  attach_function :lst_stree_new,  [ :pointer ], :pointer
  attach_function :lst_stree_free, [ :pointer ], :void
  attach_function :lst_alg_longest_common_substring, [ :pointer, :uint, :uint ], :pointer
  attach_function :lst_alg_longest_repeated_substring, [ :pointer, :uint, :uint ], :pointer

  # callback
  callback        :lst_foreach_cb,        [ :pointer ], :void
  attach_function :lst_stringset_foreach, [ :pointer, :lst_foreach_cb, :pointer], :int

  
  module_function
  def stringset_foreach(set, block=nil)
    Thread.current[:cb_stree] ||= []
    Thread.current[:cb_stree].clear
    lst_stringset_foreach(set, (block || D_CB), nil)
    Thread.current[:cb_stree]
  end

  # default callback 
  D_CB = Proc.new do |lst_str| # LST_String * string
    Thread.current[:cb_stree] << Stree.lst_string_print(lst_str)
  end

  Active = []

  class Tree
    def initialize
      Stree::Active << self
      @set = Stree.lst_stringset_new
    end

    def entries
      Stree.stringset_foreach @set
    end

    def longest_common_substring(min_size, max_size)
      build_tree
      Stree.stringset_foreach(
          Stree.lst_alg_longest_common_substring(@tree, min_size, max_size) )
    end

    def longest_repeated_substring(min_size, max_size)
      build_tree
      Stree.stringset_foreach(
          Stree.lst_alg_longest_repeated_substring(@tree, min_size, max_size) )
    end

    def build_tree
      # build only once. send #close + #build_tree to force rebuild
      @tree ||= Stree.lst_stree_new @set
    end
    
    def push(s)
      raise TypeError unless s.kind_of? String
      Stree.lst_stringset_add(@set, Stree.lst_string_new(s, 1, s.size))
    end

    def close
      # lst_stree_free should free them all.
      #Stree.lst_stringset_free(@set) unless  @set.null? # lst_string_free(lst_s)
      Stree.lst_stree_free(@tree)    unless (@tree.respond_to?(:null?) ? @tree.null? : @tree.nil?)
      Stree::Active.each_with_index{|i,idx|
          Stree::Active.delete_at(idx) if i == self }
      @tree, @set = nil, nil
    end

    alias :<< :push
    alias :flush :close
  end # Tree
end # Stree
end # FFI

