package com.fileini.storysizer.service.group.dto;

/** Aggregated dashboard data for a group estimation */
public class GroupEstimationDashboardDTO {

    private Long groupEstimationId;
    private String title;
    private String groupName;
    private int totalVoters;
    private int submittedVoters;

    // averages per parameter (1-5 scale)
    private double complexityAvg;
    private double reachAvg;
    private double dimensionsAvg;
    private double riskAvg;
    private double interactionAvg;

    // agreement index: 1.0 = full agreement (same value), 0.0 = max disagreement
    private double complexityAgreement;
    private double reachAgreement;
    private double dimensionsAgreement;
    private double riskAgreement;
    private double interactionAgreement;

    public GroupEstimationDashboardDTO() {}

    // Getters
    public Long getGroupEstimationId() { return groupEstimationId; }
    public String getTitle() { return title; }
    public String getGroupName() { return groupName; }
    public int getTotalVoters() { return totalVoters; }
    public int getSubmittedVoters() { return submittedVoters; }
    public double getComplexityAvg() { return complexityAvg; }
    public double getReachAvg() { return reachAvg; }
    public double getDimensionsAvg() { return dimensionsAvg; }
    public double getRiskAvg() { return riskAvg; }
    public double getInteractionAvg() { return interactionAvg; }
    public double getComplexityAgreement() { return complexityAgreement; }
    public double getReachAgreement() { return reachAgreement; }
    public double getDimensionsAgreement() { return dimensionsAgreement; }
    public double getRiskAgreement() { return riskAgreement; }
    public double getInteractionAgreement() { return interactionAgreement; }

    // Setters
    public void setGroupEstimationId(Long groupEstimationId) { this.groupEstimationId = groupEstimationId; }
    public void setTitle(String title) { this.title = title; }
    public void setGroupName(String groupName) { this.groupName = groupName; }
    public void setTotalVoters(int totalVoters) { this.totalVoters = totalVoters; }
    public void setSubmittedVoters(int submittedVoters) { this.submittedVoters = submittedVoters; }
    public void setComplexityAvg(double complexityAvg) { this.complexityAvg = complexityAvg; }
    public void setReachAvg(double reachAvg) { this.reachAvg = reachAvg; }
    public void setDimensionsAvg(double dimensionsAvg) { this.dimensionsAvg = dimensionsAvg; }
    public void setRiskAvg(double riskAvg) { this.riskAvg = riskAvg; }
    public void setInteractionAvg(double interactionAvg) { this.interactionAvg = interactionAvg; }
    public void setComplexityAgreement(double complexityAgreement) { this.complexityAgreement = complexityAgreement; }
    public void setReachAgreement(double reachAgreement) { this.reachAgreement = reachAgreement; }
    public void setDimensionsAgreement(double dimensionsAgreement) { this.dimensionsAgreement = dimensionsAgreement; }
    public void setRiskAgreement(double riskAgreement) { this.riskAgreement = riskAgreement; }
    public void setInteractionAgreement(double interactionAgreement) { this.interactionAgreement = interactionAgreement; }
}
