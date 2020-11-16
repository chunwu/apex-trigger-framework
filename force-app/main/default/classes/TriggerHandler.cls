// The common trigger handler that is called by every Apex trigger;
// Simply delegates the work to their before and after operations.
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