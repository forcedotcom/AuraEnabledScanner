# AuraEnabled Scanner

As part of an ongoing effort to make your org more secure, a critical update described in [this release note](https://releasenotes.docs.salesforce.com/en-us/summer20/release-notes/rn_lc_restrict_apex_authenticated_users.htm) is being activated on August 8, 2020. This may affect your org, and you should take preventative action.

![Restrict Access to @AuraEnabled Apex Methods for Authenticated Users based o User Profile](/readme-assets/the-update.png)

## Some background

The @AuraEnabled annotation enables client and server-side access to an Apex controller method. Providing this annotation makes your methods available to your Lightning components (both Lightning Web Components and Aura components). Only methods with this annotation are exposed.

## So what’s new?

Prior to the critical update, your Lightning components just worked. No extra steps necessary. With the update, you are required to specify which users can access Apex classes containing those @AuraEnabled methods. Those class permissions are granted via profiles or permission sets. Let’s take a look at what would happen using the [ApexImperativeMethod Lightning Web Component](https://github.com/trailheadapps/lwc-recipes/blob/master/force-app/main/default/lwc/apexImperativeMethod/apexImperativeMethod.js) from the LWC Recipes app once the critical update is activated.

The ApexImperativeMethod component calls an Apex method that queries and returns a list of ten contacts, and then simply displays those contacts. Here is a slimmed down version of the code — we’ll skip the HTML as it’s not relevant to our scenario, and we’ll make one minor addition: we’ll log any server-side error to the console.

```javascript
// apexImperativeMethod.js
import { LightningElement } from 'lwc';
import getContactList from '@salesforce/apex/ContactController.getContactList';

export default class ApexImperativeMethod extends LightningElement {
    contacts;
    error;

    handleLoad() {
        getContactList()
            .then((result) => {
                this.contacts = result;
                this.error = undefined;
            })
            .catch((error) => {
                console.error(error);
                this.error = error;
                this.contacts = undefined;
            });
    }
}
```
```java
// ContactController.cls
public with sharing class ContactController {
    @AuraEnabled(cacheable=true)
    public static List<Contact> getContactList() {
        return [
            SELECT Id, Name, Title, Phone, Email, Picture__c
            FROM Contact
            WHERE Picture__c != null
            WITH SECURITY_ENFORCED
            LIMIT 10
        ];
    }
}
```

Note the @AuraEnabled annotation on the `getContactList` method in the Apex controller.

Once the critical update is activated, if the running user does not have access to the `ContactController` class, the method call will fail and your app will unceremoniously crash. Let’s open up the Chrome developer console and see what gets logged.

![Server error](/readme-assets/the-error.png)

Well, that couldn’t be clearer! The user must be granted access to the `ContactController` class via their profile or a permission set.

## But there are so many classes with @AuraEnabled methods! How can I keep track of who has access to what?

We'll make it easy for you to monitor all your Apex classes with @AuraEnabled methods, understand which profiles and permission sets have access to what, and you'll be able to add or remove those permissions as you see fit. To that end, we've whipped up the fully open source **@AuraEnabled Scanner**.

https://github.com/forcedotcom/AuraEnabledScanner

Simply install the unlocked package by visiting the following URL:
`https://<myDomain>.lightning.force.com/packaging/installPackage.apexp?p0=04tB0000000ZQHxIAO`, where `<myDomain>` is the name of your custom Salesforce domain. In a sandbox or scratch org, you can also push the **@AuraEnabled Scanner** code repository into your org using the IDE of your choice.

Then launch the app by heading on over to `https://<myDomain>.lightning.force.com/c/AuraEnabledScanner.app.` The **@AuraEnabled Scanner** requires you to have the AuraEnabled Scanner User permission set. You’ll be prompted to assign it if you haven’t done so.

![AuraEnabled Scanner](/readme-assets/the-scanner.png)

The section 1 sidebar lists all the Apex classes in your org that contain one or more @AuraEnabled methods. A red flag next to a class means that not a single profile or permission set has been granted access to that class. You’ll want to check those first! Clicking on a class will populate sections 2 and 3. Section 2 highlights all the profiles and permission sets that currently have access to the selected class. You can modify those selections as you see fit. Finally, section 3 displays the code of the selected class, so you can get an idea of just what you’re granting access to.

Security is paramount to your organization. We hope the **@AuraEnabled Scanner** is one more helpful tool in your tool belt to help enforce it.

