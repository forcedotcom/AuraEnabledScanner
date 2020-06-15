/*
 * Copyright (c) 2020, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */

public without sharing class OE_ScannerRecordGetter {
  public List<ApexClass> getClasses() {
    final List<String> SKIP_CLASSES = new List<String>{
      'OE_Scanner',
      'OE_Scanner_Test',
      'OE_Scanner_TestUtils',
      'OE_ScannerRecordGetter',
      'OE_BasicStub'
    };

    return (List<ApexClass>) [
      FIND '@AuraEnabled'
      RETURNING
        ApexClass(Id, Name, Body WHERE Name NOT IN :SKIP_CLASSES ORDER BY Name)
    ][0];
  }

  public List<PermissionSet> getPermissionSets() {
    return [
      SELECT IsOwnedByProfile, Profile.Name, Label
      FROM PermissionSet
      WHERE (IsOwnedByProfile = true OR IsCustom = true)
      AND Name != :OE_Scanner.PERMISSION_SET
      ORDER BY IsOwnedByProfile, Profile.Name, Label
    ];
  }

  public List<SetupEntityAccess> getSetupEntityAccesses(Set<Id> classIds) {
    return [
      SELECT SetupEntityId, ParentId
      FROM SetupEntityAccess
      WHERE SetupEntityId IN :classIds
    ];
  }
}
