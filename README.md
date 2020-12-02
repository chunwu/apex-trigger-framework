# A simple Apex trigger framework
An Apex trigger framework that aims to separate trigger concerns, reduce programmer errors, and improve the modularity while maintaining a simple style. The following is the class diagram for quick reference:

![Class Diagram](https://force746.files.wordpress.com/2020/11/apextriggerpattern-7.png).

There are normally these concerns in Apex triggers:
* Multiple triggers can be defined for the same object and their execution order is not guaranteed.
* The before and after stages.
* Trigger operations: isInsert, isUpdate, isDelete, isUndelete.
* Individual trigger processes are normally change-based, i.e. only executed on certain records that have some change.
* Individual trigger processes may need to be switched on/off.
* Trigger logic mostly deals with a domain problem so the core logic could be executed else where - such as Apex REST API or a batch job.

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
public with sharing class TriggerHandler {
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

Here is the TriggerConfig class that shows various different configurations for different object triggers. It dynamically instantiates TriggerConfig records from a JSON static resource so as to further decouple from the individual TriggerOp implementations.
```
public inherited sharing class TriggerConfig {
    public Boolean isEnabled {get; set;}
    public TriggerOp[] beforeOps {get; private set;}
    public TriggerOp[] afterOps {get; private set;}

    private TriggerConfig(Boolean isEnabled, TriggerOp[] beforeOps, TriggerOp[] afterOps) {
        this.isEnabled = isEnabled;
        this.beforeOps = beforeOps;
        this.afterOps = afterOps;
    }

    private static final String TRIGGER_CONFIG_RESOURCE_NAME = 'TriggerConfig';

    public static final TriggerConfig ACCOUNT_CONFIG = triggerConfigMap.get('AccountConfig');
    
    // Other object trigger config
    // public static final TriggerConfig CONTACT_CONFIG = getInstance('ContactConfig');
    
    private static Map<String, TriggerConfig> triggerConfigMap {
        get {
            if (triggerConfigMap == null) {
                triggerConfigMap = new Map<String, TriggerConfig>();
                StaticResource[] srs = [select Body from StaticResource where Name = :TRIGGER_CONFIG_RESOURCE_NAME limit 1];
                if (srs.size() > 0) {
                    // Deserialize the JSON and create a TriggerConfig map
                    // ......
                }
            }
            return triggerConfigMap;
        }
        set;
    }
}
```

The the static resource TriggerConfig.json is simple like this:
```
{
    "AccountConfig": {
        "isEnabled": true,
        "beforeTriggersOpsClassNames": ["AccountTriggerOps.Validation"],
        "afterTriggerOpsClassNames": ["AccountTriggerOps.UpdateContactDescription"]
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

In summary, this Apex trigger framework provides these benefits:
* Allowing each trigger to be individually switched on/off.
* Allowing each trigger operation to be individually switched on/off.
* Promoting consideration of the before and after stages where the logic should belong to.
* Promoting consideration of the changed records that need to be processed.
* Increased modularity on managing the code.
* Simple to use (well, subject to the definition of "simple").