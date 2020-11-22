# A simple Apex Trigger pattern
An Apex trigger pattern that aims to separate trigger concerns, reduce programmer errors, and improve the modularity while maintaining a simple style.

There are normally these concerns in Apex triggers:
* Multiple triggers can be defined for the same object.
* The before and after stages.
* Trigger operations: isInsert, isUpdate, isDelete, isUndelete.
* A bulk of records is involved.
* Individual trigger processes are normally change-based, i.e. only executed on certain records that have some change.
* Individual trigger processes may need to be switched on/off in-memory or by a static configuration.
* Trigger logic mostly deals with a domain problem so it could be executed else where - such as Apex REST API or a batch job.

It's a widely accepted pattern to have one trigger per object. Further to this, keeping triggers thin has the benefit of leveraging Apex classes to organise the trigger logic. The following code shows how an AccountTrigger is written in such a pattern. It simply delegates its work to a common TriggerHandler class.
```
trigger AccountTrigger on Account (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerHandler.handle(TriggerConfig.ACCOUNT_CONFIG);
}
```

Normally the trigger logic should be either in the before or after stage, very unlikely being existent in both. Therefore separating the before and the after concerns is more useful to remove design errors. The TriggerHandler class is common in every trigger. It focuses on the before and after stages and leave the handling of the operation type to each trigger operation. The code is shown as follows:
```
/**
 * The common trigger handler that is called by every Apex trigger.
 * Simply delegates the work to config's before and after operations.
 */
public inherited sharing class TriggerHandler {
    public static void handle(TriggerConfig config) {
        if (!config.isEnabled) return;
        
        if (Trigger.isBefore) {
            for (TriggerOp operation : config.beforeOps) {
                run(operation);
            }
        }
        
        if (Trigger.isAfter) {
            for (TriggerOp operation : config.afterOps) {
                run(operation);
            }
        }
    }
    
    private static void run(TriggerOp operation) {
        if (operation.isEnabled()) {
            SObject[] sobs = operation.filter();
            if (sobs.size() > 0) {
                operation.execute(sobs);
            }
        }
    }
}
```

This is the TriggerOp interface ("TriggerOperation" is already used by Salesforce).. It represents an individual trigger operation that encapsulates some relatively independent business logic.
```
public interface TriggerOp {
    Boolean isEnabled();
    SObject[] filter();
    void execute(SObject[] sobs);
}
```

Here is the TriggerConfig class that shows various different configurations for different object triggers. It statically instantiates many TriggerConfig objects, each of which is ready to be used in their own trigger.
```
/**
 * A singleton class that presents the configuration properties of the individual triggers.
 * Instances could be further deserialised from a static resource like JSON files.
 */
public inherited sharing class TriggerConfig {
    public Boolean isEnabled {get; set;}
    public TriggerOp[] beforeOps {get; private set;}
    public TriggerOp[] afterOps {get; private set;}
    
    public static final TriggerConfig ACCOUNT_CONFIG = new TriggerConfig(
        	new TriggerOp[] {new AccountTriggerOps.Validation()},
        	new TriggerOp[] {new AccountTriggerOps.UpdateContactDescription()});
    // Other object trigger config
    
    private TriggerConfig(TriggerOp[] beforeOps, TriggerOp[] afterOps) {
        this.isEnabled = true;
        this.beforeOps = beforeOps;
        this.afterOps = afterOps;
    }
}
```

The AccountTriggerOps class is simply a superset of all TriggerOperations in relation to the Account, organised in a top-level class.
```
public with sharing class AccountTriggerOps {
    public class Validation implements TriggerOperation {
        ......
    }

    public class UpdateContactDescription implements TriggerOperation {
        ......
    }

    public class OperationC implements TriggerOperation {
        ......
    }

    public class OperationD implements TriggerOperation {
        ......
    }
}
```

## Install the unmanaged package
This repository is in SFDX format.
An unmanaged package can be intsalled here.