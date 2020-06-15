/*
 * Copyright (c) 2020, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */

@IsTest
public class OE_Scanner_TestUtils {
  static Profile standardUserProfile;
  static PermissionSet thePermissionSet;

  public static User createStandardUser(String name) {
    return createTestUser(name, getStandardUserProfile());
  }

  static Profile getStandardUserProfile() {
    if (standardUserProfile == null) {
      standardUserProfile = getProfile('Standard User');
    }
    return standardUserProfile;
  }

  static Profile getProfile(String name) {
    return [SELECT Id FROM Profile WHERE Name = :name];
  }

  static User createTestUser(String name, Profile p) {
    String orgId = UserInfo.getOrganizationId();
    String dateString = String.valueOf(Datetime.now())
      .replace(' ', '')
      .replace(':', '')
      .replace('-', '');
    Integer randomInt = Integer.valueOf(Math.rint(Math.random() * 1000000));
    String uniqueName = orgId + dateString + randomInt;

    return new User(
      LastName = name,
      Username = uniqueName + '@test' + orgId + '.org',
      Email = uniqueName + '@test' + orgId + '.org',
      EmailEncodingKey = 'ISO-8859-1',
      Alias = uniqueName.substring(18, 23),
      TimeZoneSidKey = 'America/Los_Angeles',
      LocaleSidKey = 'en_US',
      LanguageLocaleKey = 'en_US',
      ProfileId = p.Id
    );
  }

  public static void assignPermissions(User u) {
    if (u.Id != null) {
      insert new PermissionSetAssignment(
        PermissionSetId = getThePermissionSet().Id,
        AssigneeId = u.Id
      );
    }
  }

  static PermissionSet getThePermissionSet() {
    if (thePermissionSet == null) {
      thePermissionSet = [
        SELECT Id
        FROM PermissionSet
        WHERE Name = :OE_Scanner.PERMISSION_SET
      ];
    }
    return thePermissionSet;
  }

  public static Id mockId(SObjectType sObjType) {
    return mockIds(sObjType, 1)[0];
  }

  public static List<Id> mockIds(SObjectType sObjectType, Integer size) {
    String keyPrefix = sObjectType.getDescribe().getKeyPrefix();
    List<Id> ids = new List<Id>();

    for (Integer i = 0; i != size; i++) {
      ids.add(keyPrefix + '0'.repeat(12 - String.valueOf(i).length()) + i);
    }

    return ids;
  }
}
