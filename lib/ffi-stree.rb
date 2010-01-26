#
# quick test on libstree via ffi, interface without sized structs,
# inspired by github.com/tenderlove/stree
#
require 'ffi'

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
      Stree.lst_stree_free(@tree)    unless @tree.null?
      Stree::Active.each_with_index{|i,idx|
          Stree::Active.delete_at(idx) if i == self }
      @tree, @set = nil, nil
    end

    alias :<< :push
    alias :flush :close
  end # Tree
end # Stree



require 'bacon'
Bacon.summary_on_exit

describe Stree::Tree do
  # deps: v4.2 (broken 4.3-pre2)

  it 'initializes' do
    @tree = Stree::Tree.new
    @tree.entries.size.should == 0
  end

  it 'add strings to stringset' do
    @tree << 'yokatt'
    @tree.push 'nemukatt'
    ->{ @tree.push 27 }.should.raise TypeError
    @tree.entries.size.should == 2
  end

  it 'find longest common substring' do
    @tree.longest_common_substring(0,10).should == [ 'katt' ]
  end

  it 'find longest repeated substring' do
    @tree.entries.size.should == 2
    @tree.longest_repeated_substring(0,0).should == [ 'katt' ]
  end

  it '#close should free objects' do
    @tree.close
    Stree::Active.size.should == 0
    @tree.instance_eval { @set.should == nil; @view.should == nil }
  end
end


__END__
require 'benchmark'

n = 1500
Benchmark.bmbm do |x|

  x.report("init-#{n}-2") do
    n.times {
      tree = Stree::Tree.new
      tree << 'yokatt'
      tree << 'nemukatt'
      tree.longest_common_substring(0,10)
      tree.close
    } 
  end

  tree = Stree::Tree.new
  tree << 'yokatt'
  tree << 'nemukatt'

  x.report("#{n}-2") do
    n.times {
      tree.longest_common_substring(0,10)
    } 
  end

  n = 3000
  x.report("#{n}-2") do
    n.times {
      tree.longest_common_substring(0,10)
    } 
  end

  n = 6000
  x.report("#{n}-2") do
    n.times {
      tree.longest_common_substring(0,10)
    } 
  end

  n = n * 10
  x.report("#{n}-2") do
    n.times {
      tree.longest_common_substring(0,10)
    } 
  end

  tree.close
  n = 1000
  tree = Stree::Tree.new

  100.times {
    tree << 'yokatt'
    tree << 'nemukatt'
  }

  x.report("#{n}-2000") do
    n.times {
      tree.longest_common_substring(0,10)
    } 
  end

  n = n * 10
  x.report("#{n}-2000") do
    n.times {
      tree.longest_common_substring(0,10)
    } 
  end

  tree.close
  n = 10
  tree = Stree::Tree.new

  10000.times {
    tree << 'yokatt'
    tree << 'nemukatt'
  }

  x.report("#{n}-20000") do
    n.times {
      tree.longest_common_substring(0,10)
    } 
  end

  tree.close
end

