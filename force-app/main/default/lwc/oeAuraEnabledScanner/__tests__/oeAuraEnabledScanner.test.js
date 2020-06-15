/*
 * Copyright (c) 2020, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 * For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */

import { createElement } from "lwc";
import OeAuraEnabledScanner from "c/oeAuraEnabledScanner";

import hasPermission from "@salesforce/apex/OE_Scanner.hasPermission";
import scan from "@salesforce/apex/OE_Scanner.scan";

const mockScan = require("./data/classes.json");

jest.mock(
  "@salesforce/apex/OE_Scanner.hasPermission",
  () => {
    return {
      default: jest.fn()
    };
  },
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/OE_Scanner.scan",
  () => {
    return {
      default: jest.fn()
    };
  },
  { virtual: true }
);

function setupTest() {
  const element = createElement("c-oe-aura-enabled-scanner", {
    is: OeAuraEnabledScanner
  });
  document.body.appendChild(element);

  return element;
}

describe("c-oe-aura-enabled-scanner", () => {
  afterEach(() => {
    // The jsdom instance is shared across test cases in a single file so reset the DOM
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }

    // Prevent data saved on mocks from leaking between tests
    jest.clearAllMocks();
  });

  function flushPromises() {
    // eslint-disable-next-line no-undef
    return new Promise((resolve) => setImmediate(resolve));
  }

  it("should show no permissions modal", async () => {
    // Mocking Apex callouts
    hasPermission.mockResolvedValue(false);

    const element = setupTest();
    await flushPromises();

    const lookup = element.shadowRoot.querySelector("c-oe-illustration");
    expect(lookup).not.toBeNull();
  });

  it("should show first class name", async () => {
    // Mocking Apex callouts
    hasPermission.mockResolvedValue(true);
    scan.mockResolvedValue(mockScan);

    await flushPromises();

    const element = setupTest();

    // Spinner should be showing at launch
    let spinner1 = element.shadowRoot.querySelector("lightning-spinner");
    expect(spinner1).not.toBeNull();

    await flushPromises();

    let spinner2 = element.shadowRoot.querySelector("lightning-spinner");
    expect(spinner2).toBeNull();

    // Make sure there are two items in the list
    let listElm = element.shadowRoot.querySelector(".list_column ul");
    let listCount = listElm.getElementsByTagName("li").length;
    expect(listCount).toBe(2);

    // Make sure the first item is "TestBlah"
    let firstItem = element.shadowRoot.querySelector(
      ".list_column ul li:first-child span[title=TestBlah]"
    );
    expect(firstItem.textContent).toBe("TestBlah");
  });

  it("data populates after sidebar click", async () => {
    // Mocking Apex callouts
    hasPermission.mockResolvedValue(true);

    await flushPromises();

    const element = setupTest();

    scan.mockResolvedValue(mockScan);

    await flushPromises();

    let button = element.shadowRoot.querySelector(
      ".list_column ul li:first-child a"
    );
    await button.dispatchEvent(new CustomEvent("click"));

    let dualListbox = element.shadowRoot.querySelector(
      "lightning-dual-listbox"
    );

    expect(dualListbox.options).toEqual(
      mockScan[0].profiles.map((el) => ({
        label: el.name,
        value: el.id
      }))
    );

    let classTitle = element.shadowRoot.querySelector("div.classNameHeading");
    expect(classTitle.textContent).toBe("TestBlah");
  });
});
