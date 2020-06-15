/*
 * Copyright (c) 2020, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */

import { LightningElement, api } from "lwc";

export default class OeDialog extends LightningElement {
  @api title;
  @api name;
  @api message;
  @api confirmLabel;
  @api cancelLabel;
  @api originalMessage;

  handleClick(event) {
    let finalEvent = {
      originalMessage: this.originalMessage,
      status: event.target.name
    };
    this.dispatchEvent(new CustomEvent("click", { detail: finalEvent }));
  }
}
