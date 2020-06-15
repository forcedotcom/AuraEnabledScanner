/*
 * Copyright (c) 2020, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */

import { LightningElement, track } from "lwc";

import hasPermission from "@salesforce/apex/OE_Scanner.hasPermission";
import scan from "@salesforce/apex/OE_Scanner.scan";
import updateAccess from "@salesforce/apex/OE_Scanner.updateAccess";
import userId from "@salesforce/user/Id";
import hasViewSetup from "@salesforce/userPermission/ViewSetup";
import hasAssignPermissionSets from "@salesforce/userPermission/AssignPermissionSets";

import labels from "./labels";

document.title = "AuraEnabled Scanner";
document.body.style.overflow = "hidden";

export default class OeAuraEnabledScanner extends LightningElement {
  label = labels;
  loading = true;
  permissionCheck = false;
  appLoaded = false;
  showPermissionsError = false;
  showOptions = false;
  @track classes;
  @track selectedClass;
  @track profileOptions = [];
  @track selectedProfiles = [];
  @track permSetOptions = [];
  @track selectedPermSets = [];
  className = "";
  originalSelectedProfileIds;
  originalSelectedPermSetIds;
  profileIdsToInsert = [];
  profileIdsToDelete = [];
  permSetIdsToInsert = [];
  permSetIdsToDelete = [];
  activeSections = ["A", "B"];
  showConfirmDialog = false;
  showConfirmDialogId = "";

  async connectedCallback() {
    try {
      const userHasPermission = await hasPermission();

      if (userHasPermission) {
        this.classes = await scan();
        this.appLoaded = true;
      } else {
        this.showPermissionsError = true;
        console.log("Missing permissions");
      }
    } catch (e) {
      if (
        e.body.message.includes(
          "You do not have access to the Apex class named 'OE_Scanner'"
        )
      ) {
        this.showPermissionsError = true;
      } else {
        console.error(e);
      }
    } finally {
      this.loading = false;
    }
  }

  handleClassClick(event) {
    this.showOptions = true;
    if (
      !this.selectedClass ||
      event.currentTarget.dataset.id !== this.selectedClass.id
    ) {
      if (
        !this.profileIdsToDelete.length &&
        !this.profileIdsToInsert.length &&
        !this.permSetIdsToInsert.length &&
        !this.permSetIdsToDelete.length
      ) {
        this.setPermissions(event.currentTarget.dataset.id);
      } else {
        this.showConfirmDialog = true;
        this.showConfirmDialogId = event.currentTarget.dataset.id;
      }
    }
  }

  highlightClick(classId) {
    let oldLink = this.template.querySelector(
      ".splitview a[aria-selected='true']"
    );
    if (oldLink !== null) oldLink.setAttribute("aria-selected", "false");
    let newLink = this.template.querySelector(
      ".splitview a[data-id='" + classId + "']"
    );
    if (newLink !== null) newLink.setAttribute("aria-selected", "true");
  }

  handleDialogClick(event) {
    if (event.detail !== 1 && event.detail.status === "confirm") {
      this.setPermissions(this.showConfirmDialogId);
    }
    this.showConfirmDialog = false;
  }

  openSetup() {
    window.open(
      "/lightning/setup/PermSets/page?address=%2Fudd%2FPermissionSet%2FassignPermissionSet.apexp%3FuserId%3D" +
        userId,
      "_blank"
    );
  }

  setPermissions(classId) {
    this.highlightClick(classId);
    this.selectedClass = this.classes.find((c) => c.id === classId);
    this.profileIdsToInsert = [];
    this.profileIdsToDelete = [];
    this.permSetIdsToInsert = [];
    this.permSetIdsToDelete = [];
    this.className = this.selectedClass.name;
    this.selectedProfiles = this.selectedClass.selectedProfiles;

    this.profileOptions = this.selectedClass.profiles.map((profile) => ({
      label: profile.name,
      value: profile.id
    }));

    this.selectedPermSets = this.selectedClass.selectedPermSets;

    this.permSetOptions = this.selectedClass.permSets.map((permSet) => ({
      label: permSet.name,
      value: permSet.id
    }));

    this.originalSelectedProfileIds = [...this.selectedProfiles];
    this.originalSelectedPermSetIds = [...this.selectedPermSets];
  }

  handleProfileChange(event) {
    this.profileIdsToInsert = event.detail.value.filter(
      (x) =>
        !this.originalSelectedProfileIds.length ||
        !x.includes(this.originalSelectedProfileIds)
    );

    this.profileIdsToDelete = this.originalSelectedProfileIds.filter(
      (x) => !event.detail.value.includes(x)
    );
  }

  handlePermSetChange(event) {
    this.permSetIdsToInsert = event.detail.value.filter(
      (x) =>
        !this.originalSelectedPermSetIds.length ||
        !x.includes(this.originalSelectedPermSetIds)
    );

    this.permSetIdsToDelete = this.originalSelectedPermSetIds.filter(
      (x) => !event.detail.value.includes(x)
    );
  }

  async update() {
    this.loading = true;
    try {
      this.classes = await updateAccess({
        entityIdsToDelete: [
          ...this.profileIdsToDelete,
          ...this.permSetIdsToDelete
        ],
        entitiesToInsert: [
          ...this.profileIdsToInsert,
          ...this.permSetIdsToInsert
        ].map((x) => ({
          SetupEntityId: this.selectedClass.id,
          ParentId: x
        }))
      });
      this.setPermissions(this.selectedClass.id);
    } catch (e) {
      console.error(e);
    } finally {
      this.loading = false;
    }
  }

  get isSaveDisabled() {
    return (
      !this.profileIdsToDelete.length &&
      !this.profileIdsToInsert.length &&
      !this.permSetIdsToInsert.length &&
      !this.permSetIdsToDelete.length
    );
  }

  get showOpenSetupButton() {
    return hasViewSetup && hasAssignPermissionSets;
  }
}
