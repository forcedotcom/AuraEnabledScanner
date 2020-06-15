/*
 * Copyright (c) 2020, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */

import { LightningElement, api } from "lwc";
import noAccess2 from "c/oeIllustrator_noAccess2";

export default class OeIllustrator extends LightningElement {
  @api artworkName;
  @api heading;
  @api message;
  @api size = "small";

  get wrapperClass() {
    return `slds-illustration slds-illustration_${this.size}`;
  }

  renderedCallback() {
    this.renderSvg();
  }

  renderSvg() {
    const selection = this.template.querySelector(".container");

    if (this.artworkName) {
      switch (this.artworkName.toLowerCase()) {
        case "no access 2":
          noAccess2(selection);
          break;
        default:
          // eslint-disable-next-line no-console
          console.warn(
            "Could not find artwork matching artworkName variable: " +
              this.artworkName
          );
      }
    }
  }
}
