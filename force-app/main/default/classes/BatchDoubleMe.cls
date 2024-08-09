public  class BatchDoubleMe implements Queueable {

    public List<DoubleMe.ProductAndDiscount> clonedProductAndDiscountWrap = new List<DoubleMe.ProductAndDiscount>();
    
    public BatchDoubleMe(List<DoubleMe.ProductAndDiscount> clonedWrapper) {
        this.clonedProductAndDiscountWrap = clonedWrapper;
    }
 
    public void execute(QueueableContext context) {
        string exceptionString = 'The following exception has occurred: ';
        String contactAdminError = ' kindly Contact to Admin';
        try {
            // Method call to copy price levels
            clonedProductAndDiscountWrap = insertClonedPriceLevelRecords(clonedProductAndDiscountWrap);
            
            //copy planned billing schedule.
            clonedProductAndDiscountWrap = insertClonedPlannedBillingSchedule(clonedProductAndDiscountWrap);

        }catch (QueryException e) {
            System.debug('Query Exception hit' + e.getStackTraceString());
            throw new AuraHandledException( exceptionString +  e.getStackTraceString() + contactAdminError);


        }catch(DmlException e){
                //If a DML exception occurs it will go to this statement
                System.debug('DmlException hit ' + e.getStackTraceString());
                throw new AuraHandledException( exceptionString +  e.getStackTraceString() + contactAdminError);

        }catch (Exception e) {
                //Any other exceptions that occur will go here
                System.debug('Exception hit' + e.getStackTraceString());
                throw new AuraHandledException( exceptionString +  e.getStackTraceString() + contactAdminError);
        } finally {
                // for future use
        }
    }
 

    /*
    * Clone the price level records and return the wrapper updated with inserted record ids
    */
    private static List<DoubleMe.ProductAndDiscount> insertClonedPriceLevelRecords(
        List<DoubleMe.ProductAndDiscount> clonedProductDiscountWrapper
    ) {
        List<TREX1__Price_Level__c> listPriceLevels = new List<TREX1__Price_Level__c>();
        for(DoubleMe.ProductAndDiscount productAndDisc : clonedProductDiscountWrapper) {
            if(productAndDisc != null && productAndDisc.priceLevels != null) {
                for(DoubleMe.PriceLevel pl : productAndDisc.priceLevels) {
                    pl.priceLevel = pl.priceLevel.clone(false);
                    pl.priceLevel.TREX1__Product__c = productAndDisc.productAndDiscount.Id;
                    listPriceLevels.add(pl.priceLevel);
                }
            }
        }

        insert listPriceLevels;
        return clonedProductDiscountWrapper;
    }

    /*
    * Clone the planned billing schedule and insert to return the response
    */
    private static List<DoubleMe.ProductAndDiscount> insertClonedPlannedBillingSchedule(
        List<DoubleMe.ProductAndDiscount> clonedProductDiscountWrapper
    ) {
        List<TREX1__Planned_Billing_Schedule__c> listPlannedBillingSch = new List<TREX1__Planned_Billing_Schedule__c>();
        for(DoubleMe.ProductAndDiscount productAndDisc : clonedProductDiscountWrapper) {
            if(productAndDisc != null && productAndDisc.priceLevels != null) {
                for(DoubleMe.PriceLevel pl : productAndDisc.priceLevels) {
                    if(pl != null && pl.plannedBillingSchedules != null) {
                        for(DoubleMe.PlannedBillingSchedule plannedBS : pl.plannedBillingSchedules) {
                            plannedBS.plannedBillingSch = plannedBS.plannedBillingSch.clone(false);
                            plannedBS.plannedBillingSch.TREX1__Price_Level__c = pl.priceLevel.Id;
                            listPlannedBillingSch.add(plannedBS.plannedBillingSch);
                        }
                    }
                }
            }
        }

        insert listPlannedBillingSch;
        return clonedProductDiscountWrapper;
    }
 }