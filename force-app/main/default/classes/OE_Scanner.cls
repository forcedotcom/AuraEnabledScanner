/*
 * Copyright (c) 2020, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */

public without sharing class OE_Scanner {
  public static final String PERMISSION_SET = 'AuraEnabledScannerUser';

  @TestVisible
  static OE_ScannerRecordGetter recordGetter = new OE_ScannerRecordGetter();

  @AuraEnabled
  public static Boolean hasPermission() {
    return [
        SELECT COUNT()
        FROM PermissionSetAssignment
        WHERE
          AssigneeId = :UserInfo.getUserId()
          AND PermissionSet.Name = :PERMISSION_SET
      ] > 0;
  }

  @AuraEnabled
  public static List<AuraEnabledClass> scan() {
    Map<Id, ApexClass> classesById = new Map<Id, ApexClass>(
      recordGetter.getClasses()
    );

    List<PermissionSet> psets = recordGetter.getPermissionSets();

    Map<Id, Map<Id, Id>> accessIdsByClassIdByPermSetId = new Map<Id, Map<Id, Id>>();

    for (
      SetupEntityAccess a : recordGetter.getSetupEntityAccesses(
        classesById.keySet()
      )
    ) {
      Map<Id, Id> accessIdsByClassId = accessIdsByClassIdByPermSetId.get(
        a.ParentId
      );
      if (accessIdsByClassId == null) {
        accessIdsByClassId = new Map<Id, Id>();
      }
      accessIdsByClassId.put(a.SetupEntityId, a.Id);
      accessIdsByClassIdByPermSetId.put(a.ParentId, accessIdsByClassId);
    }

    List<AuraEnabledClass> auraEnabledClasses = new List<AuraEnabledClass>();

    for (Id cId : classesById.keySet()) {
      ApexClass c = classesById.get(cId);
      AuraEnabledClass aec = new AuraEnabledClass(c);

      for (PermissionSet pset : psets) {
        Map<Id, Id> accessIdsByClassId = accessIdsByClassIdByPermSetId.get(
          pset.Id
        );
        if (accessIdsByClassId == null || accessIdsByClassId.get(cId) == null) {
          aec.addBlockedAccess(pset);
        } else {
          aec.addAllowedAccess(pset, accessIdsByClassId.get(cId));
        }
      }

      aec.setHasNoPermissions();

      auraEnabledClasses.add(aec);
    }

    return auraEnabledClasses;
  }

  @TestVisible
  class AuraEnabledClass {
    @AuraEnabled
    public Id id { get; private set; }
    @AuraEnabled
    public String name { get; private set; }
    @AuraEnabled
    public String code { get; private set; }
    @AuraEnabled
    public List<Id> selectedProfiles { get; private set; }
    @AuraEnabled
    public List<Id> selectedPermSets { get; private set; }
    @AuraEnabled
    public List<Access> profiles { get; private set; }
    @AuraEnabled
    public List<Access> permSets { get; private set; }
    @AuraEnabled
    public Boolean hasNoPermissions { get; private set; }

    AuraEnabledClass(ApexClass c) {
      this.id = c.Id;
      this.name = c.Name;
      this.code = c.Body;

      selectedProfiles = new List<Id>();
      selectedPermSets = new List<Id>();
      profiles = new List<Access>();
      permSets = new List<Access>();
    }

    void addAllowedAccess(PermissionSet p, Id setupEntityAccessId) {
      if (p.IsOwnedByProfile) {
        profiles.add(new Access(setupEntityAccessId, p.Profile.Name));
        selectedProfiles.add(setupEntityAccessId);
      } else {
        permSets.add(new Access(setupEntityAccessId, p.Label));
        selectedPermSets.add(setupEntityAccessId);
      }
    }

    void addBlockedAccess(PermissionSet p) {
      if (p.IsOwnedByProfile) {
        profiles.add(new Access(p.Id, p.Profile.Name));
      } else {
        permSets.add(new Access(p.Id, p.Label));
      }
    }

    void setHasNoPermissions() {
      hasNoPermissions =
        selectedProfiles.isEmpty() && selectedPermSets.isEmpty();
    }
  }

  class Access {
    @AuraEnabled
    public Id id { get; private set; }
    @AuraEnabled
    public String name { get; private set; }

    Access(Id id, String name) {
      this.id = id;
      this.name = name;
    }
  }

  @AuraEnabled
  public static List<AuraEnabledClass> updateAccess(
    List<Id> entityIdsToDelete,
    List<SetupEntityAccess> entitiesToInsert
  ) {
    if (entityIdsToDelete != null && !entityIdsToDelete.isEmpty()) {
      for (Id entityId : entityIdsToDelete) {
        if (entityId.getSobjectType() != SetupEntityAccess.getSObjectType()) {
          return scan();
        }
      }
      Database.delete(entityIdsToDelete, false);
    }

    if (entitiesToInsert != null && !entitiesToInsert.isEmpty()) {
      Database.insert(entitiesToInsert, false);
    }

    return scan();
  }
}
