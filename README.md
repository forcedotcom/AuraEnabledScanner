# AuraEnabled Scanner

On 8/9/2020, a critical update will enforce user profile restrictions for Apex classes used by Lightning components (both Lightning web components and Aura components). An authenticated user will only be able to access an @AuraEnabled Apex method when the user’s profile (or permission set) allows access to the Apex class. After the update, any Lightning component calling these classes will throw an exception.

The AuraEnabled Scanner scans your org and list all Apex classes containing the @AuraEnabled annotation. An authorized user is then able to add or remove class permissions to profile and permission sets as they see fit.

https://releasenotes.docs.salesforce.com/en-us/winter20/release-notes/rn_lc_restrict_apex_authenticated_users.htm
