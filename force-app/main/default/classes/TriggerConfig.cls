/**
 * A singleton class that presents the configuration properties of the individual triggers.
 * Instances are created dynamically from a JSON static resource.
 */
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
    // public static final TriggerConfig CONTACT_CONFIG = getInstance('ContactConfig');
    // Other object trigger config
    
    private static Map<String, TriggerConfig> triggerConfigMap {
        get {
            if (triggerConfigMap == null) {
                triggerConfigMap = new Map<String, TriggerConfig>();
                StaticResource[] srs = [select Body from StaticResource where Name = :TRIGGER_CONFIG_RESOURCE_NAME limit 1];
                if (srs.size() > 0) {
                    String config = srs[0].Body.toString();
                    Map<String, TriggerConfigX> triggerConfigMapX = (Map<String, TriggerConfigX>) Json.deserialize(config, Map<String, TriggerConfigX>.class);
                    for (String name : triggerConfigMapX.keySet()) {
                        TriggerConfigX tcx = triggerConfigMapX.get(name);
                        TriggerOp[] beforeOps = newInstancesFrom(tcx.beforeTriggersOpsClassNames);
                        TriggerOp[] afterOps = newInstancesFrom(tcx.afterTriggerOpsClassNames);
                        TriggerConfig tc = new TriggerConfig(tcx.isEnabled, beforeOps, afterOps);
                        triggerConfigMap.put(name, tc);
                    }
                }
            }
            return triggerConfigMap;
        }
        set;
    }

    private static TriggerOp[] newInstancesFrom(String[] classNames) {
        TriggerOp[] result = new TriggerOp[] {};
        for (String className : classNames) {
            Type t = Type.forName(className);
            result.add((TriggerOp) t.newInstance());
        }
        return result;
    }

    // A class the JSON static resource is deserialized to
    private class TriggerConfigX {
        Boolean isEnabled;
        String[] beforeTriggersOpsClassNames;
        String[] afterTriggerOpsClassNames;
    }
}