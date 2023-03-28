## Removing mempool transactions

#### MemPoolRemovalReasons:
```
    EXPIRY,      //!< Expired from mempool
    SIZELIMIT,   //!< Removed in size limiting
    REORG,       //!< Removed for reorganization
    BLOCK,       //!< Removed for block
    CONFLICT,    //!< Removed for conflict with in-block transaction
    REPLACED,    //!< Removed for replacement
```

#### Code paths for each reason:
<img src="/images/mempool-removal-reasons.jpg">

#### Removing for reorg:
1. Conflicts -> eg. miner 1 saw tx A, new block includes tx B which RBFs tx A.
2. Finality -> eg. new tip has more work but smaller height & now the coinbase
   spend is premature. Or other finality rules like CLTV are not met.
