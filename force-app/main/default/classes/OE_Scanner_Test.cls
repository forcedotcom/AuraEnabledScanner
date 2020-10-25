/*
 * Copyright (c) 2020, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */

@IsTest
class OE_Scanner_Test {
  @IsTest
  static void shouldAcknowledgeIfUserHasScannerPermSet() {
    User u = OE_Scanner_TestUtils.createStandardUser('blah');
    insert u;

    System.runAs(u) {
      System.assert(!OE_Scanner.hasPermission());
    }

    OE_Scanner_TestUtils.assignPermissions(u);

    System.runAs(u) {
      System.assert(OE_Scanner.hasPermission());
    }
  }

  @IsTest
  static void shouldReturnAuraEnabledClassesAndAssociatedPermissions() {
    List<Id> classIds = OE_Scanner_TestUtils.mockIds(
      ApexClass.getSObjectType(),
      2
    );

    List<ApexClass> classes = new List<ApexClass>{
      new ApexClass(
        Id = classIds[0],
        Name = 'AuraEnabledClass',
        Body = '@AuraEnabled whatever'
      ),
      new ApexClass(
        Id = classIds[1],
        Name = 'AnotherAuraEnabledClass',
        Body = '@AuraEnabled also whatever'
      )
    };

    List<Id> permissionSetIds = OE_Scanner_TestUtils.mockIds(
      PermissionSet.getSObjectType(),
      2
    );

    List<PermissionSet> permSets = (List<PermissionSet>) JSON.deserialize(
      '[' +
      '  {' +
      '    "Id": "' +
      permissionSetIds[0] +
      '",' +
      '    "IsOwnedByProfile": true,' +
      '    "Label": "Profile Permission Set",' +
      '    "Profile": {' +
      '      "Name": "Some Profile"' +
      '    }' +
      '  },' +
      '  {' +
      '    "Id": "' +
      permissionSetIds[1] +
      '",' +
      '    "IsOwnedByProfile": false,' +
      '    "Label": "Permission Set Permission Set"' +
      '  }' +
      ']',
      List<PermissionSet>.class
    );

    List<Id> setupEntityAccessIds = OE_Scanner_TestUtils.mockIds(
      SetupEntityAccess.getSObjectType(),
      2
    );

    List<SetupEntityAccess> setupEntityAccesses = new List<SetupEntityAccess>{
      new SetupEntityAccess(
        Id = setupEntityAccessIds[0],
        SetupEntityId = classes[0].Id,
        ParentId = permSets[0].Id
      ),
      new SetupEntityAccess(
        Id = setupEntityAccessIds[1],
        SetupEntityId = classes[1].Id,
        ParentId = permSets[1].Id
      )
    };

    OE_Scanner.recordGetter = (OE_ScannerRecordGetter) new OE_BasicStub(
        OE_ScannerRecordGetter.class
      )
      .withReturnValue('getClasses', classes)
      .withReturnValue('getPermissionSets', permSets)
      .withReturnValue(
        'getSetupEntityAccesses',
        Set<Id>.class,
        setupEntityAccesses
      )
      .createMock();

    Test.startTest();
    List<OE_Scanner.AuraEnabledClass> auraEnabledClasses = OE_Scanner.scan();
    Test.stopTest();

    System.assertEquals(2, auraEnabledClasses.size());

    System.assertEquals(classes[0].Id, auraEnabledClasses[0].id);
    System.assertEquals(classes[0].Name, auraEnabledClasses[0].name);
    System.assertEquals(classes[0].Body, auraEnabledClasses[0].code);
    System.assertEquals(1, auraEnabledClasses[0].selectedProfiles.size());
    System.assertEquals(
      setupEntityAccesses[0].Id,
      auraEnabledClasses[0].selectedProfiles[0]
    );
    System.assert(auraEnabledClasses[0].selectedPermSets.isEmpty());
    System.assertEquals(1, auraEnabledClasses[0].profiles.size());
    System.assertEquals(
      setupEntityAccesses[0].Id,
      auraEnabledClasses[0].profiles[0].id
    );
    System.assertEquals(
      permSets[0].Profile.Name,
      auraEnabledClasses[0].profiles[0].name
    );
    System.assertEquals(1, auraEnabledClasses[0].permSets.size());
    System.assertEquals(permSets[1].Id, auraEnabledClasses[0].permSets[0].id);
    System.assertEquals(
      permSets[1].Label,
      auraEnabledClasses[0].permSets[0].name
    );

    System.assertEquals(classes[1].Id, auraEnabledClasses[1].id);
    System.assertEquals(classes[1].Name, auraEnabledClasses[1].name);
    System.assertEquals(classes[1].Body, auraEnabledClasses[1].code);
    System.assert(auraEnabledClasses[1].selectedProfiles.isEmpty());
    System.assertEquals(1, auraEnabledClasses[1].selectedPermSets.size());
    System.assertEquals(
      setupEntityAccesses[1].Id,
      auraEnabledClasses[1].selectedPermSets[0]
    );
    System.assertEquals(1, auraEnabledClasses[1].profiles.size());
    System.assertEquals(permSets[0].Id, auraEnabledClasses[1].profiles[0].id);
    System.assertEquals(
      permSets[0].Profile.Name,
      auraEnabledClasses[1].profiles[0].name
    );
    System.assertEquals(1, auraEnabledClasses[1].permSets.size());
    System.assertEquals(
      setupEntityAccesses[1].Id,
      auraEnabledClasses[1].permSets[0].id
    );
    System.assertEquals(
      permSets[1].Label,
      auraEnabledClasses[1].permSets[0].name
    );
  }

  @IsTest
  static void shouldUpdateAccesses() {
    Id permSetId = [
      SELECT Id
      FROM PermissionSet
      WHERE Name = :OE_Scanner.PERMISSION_SET
    ]
    .Id;
    Id classIdForDeletion = [SELECT Id FROM ApexClass WHERE Name = 'OE_Scanner']
    .Id;
    Id classIdForInsertion = [
      SELECT Id
      FROM ApexClass
      WHERE Name = 'OE_Scanner_Test'
    ]
    .Id;

    Id accessIdToDelete = [
      SELECT Id
      FROM SetupEntityAccess
      WHERE ParentId = :permSetId AND SetupEntityId = :classIdForDeletion
      LIMIT 1
    ]
    .Id;

    Test.startTest();
    OE_Scanner.updateAccess(
      new List<Id>{ accessIdToDelete },
      new List<SetupEntityAccess>{
        new SetupEntityAccess(
          ParentId = permSetId,
          SetupEntityId = classIdForInsertion
        )
      }
    );
    Test.stopTest();

    System.assertEquals(
      0,
      [SELECT COUNT() FROM SetupEntityAccess WHERE Id = :accessIdToDelete]
    );

    System.assert(
      [
        SELECT COUNT()
        FROM SetupEntityAccess
        WHERE ParentId = :permSetId AND SetupEntityId = :classIdForInsertion
      ] > 0
    );
  }

  @IsTest
  static void shouldNOTUpdateAccessesBecauseAccountIdInTheMix() {
    Id permSetId = [
      SELECT Id
      FROM PermissionSet
      WHERE Name = :OE_Scanner.PERMISSION_SET
    ]
    .Id;
    Id classIdForDeletion = [SELECT Id FROM ApexClass WHERE Name = 'OE_Scanner']
    .Id;
    Id classIdForInsertion = [
      SELECT Id
      FROM ApexClass
      WHERE Name = 'OE_Scanner_Test'
    ]
    .Id;

    Id accessIdToDelete = [
      SELECT Id
      FROM SetupEntityAccess
      WHERE ParentId = :permSetId AND SetupEntityId = :classIdForDeletion
      LIMIT 1
    ]
    .Id;

    Account a = new Account(Name = 'blah');
    insert a;

    Test.startTest();
    OE_Scanner.updateAccess(
      new List<Id>{ accessIdToDelete, a.Id },
      new List<SetupEntityAccess>{
        new SetupEntityAccess(
          ParentId = permSetId,
          SetupEntityId = classIdForInsertion
        )
      }
    );
    Test.stopTest();

    System.assertEquals(
      1,
      [SELECT COUNT() FROM SetupEntityAccess WHERE Id = :accessIdToDelete]
    );

    System.assertEquals(1, [SELECT COUNT() FROM Account WHERE Id = :a.Id]);

    System.assertEquals(
      0,
      [
        SELECT COUNT()
        FROM SetupEntityAccess
        WHERE ParentId = :permSetId AND SetupEntityId = :classIdForInsertion
      ]
    );
  }

  @IsTest
  static void coverage() {
    OE_ScannerRecordGetter recordGetter = new OE_ScannerRecordGetter();
    recordGetter.getClasses();
    recordGetter.getPermissionSets();
    recordGetter.getSetupEntityAccesses(null);
  }
}
