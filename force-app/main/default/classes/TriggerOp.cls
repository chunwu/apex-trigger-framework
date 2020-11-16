/**
 * This interface represents an individual trigger operation that encapsulates relatively independent 
 * business logic in a trigger context.
 * The caller is the @TriggerHandler class that does these steps:
 *     Use the isEnabled() method check if the operation needs to be executed;
 *     Call the filter() method to return the sobjects that are concerned; normally the ones with some change;
 *     Execute the business logic that is implemented in the execute() method.
 */
public interface TriggerOp {
    Boolean isEnabled();
    SObject[] filter();
    void execute(SObject[] sobs);
}