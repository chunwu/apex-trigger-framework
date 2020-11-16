/**
 * A singleton class that presents the configuration properties of the indvidual triggers.
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
