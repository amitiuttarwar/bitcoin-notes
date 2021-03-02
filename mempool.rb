# runs getrawmempool on an active bitcoind process
# to find the mempool entry date of the oldest txn
# in a wildly inefficient manner

require 'json'
require 'pp'

output = `src/bitcoin-cli getrawmempool` # string
hashes = output.split # array of strings, each string is the txn hash
hashes.delete_at(0)
hashes.delete_at(hashes.size - 1)
puts "There are #{hashes.length()} txns in the mempool"

output = `src/bitcoin-cli getrawmempool true`
txns = JSON.parse(output)

min_time = Time.now.to_i + 1000000
min_txhsh = 0
puts "min_time starting at #{min_time}"
count = 0
# keys are txhshes, data is a hash of returned json object
txns.each_pair do |txhsh, data|
  if data['time'] < min_time
    min_time = data['time']
    min_txhsh = txhsh
    puts "updating min_time to #{min_time}, min_txhsh #{txhsh}"
  end

  count += 1
end

puts "==============="
puts "processed #{count} txns"
puts "final result: tx #{min_txhsh} was in mempool at #{Time.at(min_time)}"
~
~
~
~
~
~
~
~
~
~
~
~
~
~
~
~
~
~
~
~
~
~
~
~
~
~
~
~
~
~
~
                                                                                              1,1           All