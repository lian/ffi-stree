require File.join(File.dirname(__FILE__), '../lib/ffi-stree.rb')

require 'bacon'
Bacon.summary_on_exit

describe FFI::Stree::Tree do
  # deps: v4.2 (broken 4.3-pre2)

  it 'initializes' do
    @tree = FFI::Stree::Tree.new
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
    @tree.instance_eval { @tree.null?.should == false }
    @tree.close
    FFI::Stree::Active.size.should == 0
    @tree.instance_eval { @set.should == nil; @view.should == nil; @tree.should == nil }
  end
end


__END__
require 'benchmark'

n = 1500
Benchmark.bmbm do |x|

  x.report("init-#{n}-2") do
    n.times {
      tree = FFI::Stree::Tree.new
      tree << 'yokatt'
      tree << 'nemukatt'
      tree.longest_common_substring(0,10)
      tree.close
    } 
  end

  tree = FFI::Stree::Tree.new
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
  tree = FFI::Stree::Tree.new

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
  tree = FFI::Stree::Tree.new

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

