import { DaemonsPageHelper } from './daemons.po';

describe('RGW daemons page', () => {
  const daemons = new DaemonsPageHelper();

  beforeEach(() => {
    cy.login();
    Cypress.Cookies.preserveOnce('token');
    daemons.navigateTo();
  });

  describe('breadcrumb and tab tests', () => {
    it('should open and show breadcrumb', () => {
      daemons.expectBreadcrumbText('Daemons');
    });

    it('should show two tabs', () => {
      daemons.getTabsCount().should('eq', 2);
    });

    it('should show daemons list tab at first', () => {
      daemons.getTabText(0).should('eq', 'Daemons List');
    });

    it('should show overall performance as a second tab', () => {
      daemons.getTabText(1).should('eq', 'Overall Performance');
    });
  });

  describe('details and performance counters table tests', () => {
    it('should check that details/performance tables are visible when daemon is selected', () => {
      daemons.checkTables();
    });
  });
});
