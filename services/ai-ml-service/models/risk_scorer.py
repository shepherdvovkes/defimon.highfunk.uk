import pandas as pd
from typing import Dict, List
import os

class RiskScoringModel:
    def __init__(self):
        self.weights = {
            "smart_contract_risk": 0.3,
            "liquidity_risk": 0.25,
            "market_risk": 0.2,
            "counterparty_risk": 0.15,
            "governance_risk": 0.1
        }
    
    def calculate_protocol_risk(self, protocol_data: Dict) -> Dict:
        """Calculate comprehensive risk score for DeFi protocol"""
        risks = {
            "smart_contract_risk": self._assess_smart_contract_risk(protocol_data),
            "liquidity_risk": self._assess_liquidity_risk(protocol_data),
            "market_risk": self._assess_market_risk(protocol_data),
            "counterparty_risk": self._assess_counterparty_risk(protocol_data),
            "governance_risk": self._assess_governance_risk(protocol_data)
        }
        
        # Calculate weighted overall risk score
        overall_risk = sum(
            risks[risk_type] * self.weights[risk_type] 
            for risk_type in risks
        )
        
        return {
            "overall_risk_score": overall_risk,
            "risk_level": self._categorize_risk(overall_risk),
            "detailed_risks": risks,
            "recommendations": self._generate_recommendations(risks),
            "timestamp": pd.Timestamp.now().isoformat()
        }
    
    def _assess_smart_contract_risk(self, data: Dict) -> float:
        """Assess smart contract security risk (0-1, higher = riskier)"""
        factors = {
            "audit_status": data.get("audited", False),
            "audit_firm_reputation": data.get("audit_firm_rating", 0),
            "code_complexity": data.get("contract_complexity_score", 0.5),
            "upgrade_mechanism": data.get("upgradeable", True),
            "time_since_deployment": data.get("days_since_deployment", 0),
            "bug_bounty_program": data.get("has_bug_bounty", False)
        }
        
        risk_score = 0.5  # Base risk
        
        # Audit adjustments
        if factors["audit_status"]:
            risk_score -= 0.2
            risk_score -= factors["audit_firm_reputation"] * 0.1
        else:
            risk_score += 0.3
        
        # Time-based adjustment
        if factors["time_since_deployment"] > 365:
            risk_score -= 0.1  # Battle tested
        elif factors["time_since_deployment"] < 30:
            risk_score += 0.2  # Very new
        
        # Other factors
        if factors["bug_bounty_program"]:
            risk_score -= 0.1
        if factors["upgrade_mechanism"]:
            risk_score += 0.1  # Upgradeable contracts have admin risk
        
        return max(0, min(1, risk_score))
    
    def _assess_liquidity_risk(self, data: Dict) -> float:
        """Assess liquidity risk based on TVL, volume, and concentration"""
        tvl = data.get("total_value_locked", 0)
        daily_volume = data.get("volume_24h", 0)
        volume_tvl_ratio = daily_volume / tvl if tvl > 0 else 0
        
        # Liquidity concentration (Herfindahl index)
        pool_distributions = data.get("pool_distributions", [])
        concentration = sum(share**2 for share in pool_distributions) if pool_distributions else 1
        
        # Base risk from volume/TVL ratio
        if volume_tvl_ratio < 0.01:
            liquidity_risk = 0.8  # Very low liquidity
        elif volume_tvl_ratio < 0.05:
            liquidity_risk = 0.6
        elif volume_tvl_ratio < 0.1:
            liquidity_risk = 0.4
        else:
            liquidity_risk = 0.2
        
        # Adjust for concentration
        liquidity_risk += concentration * 0.3
        
        return max(0, min(1, liquidity_risk))
    
    def _assess_market_risk(self, data: Dict) -> float:
        """Assess market risk based on volatility and market conditions"""
        price_volatility = data.get("price_volatility_30d", 0.5)
        market_cap = data.get("market_cap", 0)
        trading_volume = data.get("volume_24h", 0)
        
        # Market cap risk
        if market_cap < 1000000:  # < $1M
            market_risk = 0.8
        elif market_cap < 10000000:  # < $10M
            market_risk = 0.6
        elif market_cap < 100000000:  # < $100M
            market_risk = 0.4
        else:
            market_risk = 0.2
        
        # Volatility adjustment
        market_risk += price_volatility * 0.3
        
        # Volume adjustment
        if trading_volume < 100000:  # < $100K daily volume
            market_risk += 0.2
        
        return max(0, min(1, market_risk))
    
    def _assess_counterparty_risk(self, data: Dict) -> float:
        """Assess counterparty risk based on user concentration and governance"""
        user_concentration = data.get("top_10_users_percentage", 0.5)
        governance_decentralization = data.get("governance_decentralization_score", 0.5)
        multisig_required = data.get("multisig_required", False)
        
        counterparty_risk = 0.5  # Base risk
        
        # User concentration risk
        if user_concentration > 0.8:
            counterparty_risk += 0.3
        elif user_concentration > 0.5:
            counterparty_risk += 0.2
        
        # Governance risk
        counterparty_risk += (1 - governance_decentralization) * 0.2
        
        # Multisig protection
        if multisig_required:
            counterparty_risk -= 0.1
        
        return max(0, min(1, counterparty_risk))
    
    def _assess_governance_risk(self, data: Dict) -> float:
        """Assess governance risk based on token distribution and voting mechanisms"""
        token_concentration = data.get("top_10_token_holders_percentage", 0.5)
        voting_power_decentralization = data.get("voting_power_decentralization", 0.5)
        governance_token_locked = data.get("governance_token_locked_percentage", 0)
        
        governance_risk = 0.5  # Base risk
        
        # Token concentration risk
        if token_concentration > 0.8:
            governance_risk += 0.3
        elif token_concentration > 0.5:
            governance_risk += 0.2
        
        # Voting power risk
        governance_risk += (1 - voting_power_decentralization) * 0.2
        
        # Token lock-up benefit
        governance_risk -= governance_token_locked * 0.1
        
        return max(0, min(1, governance_risk))
    
    def _categorize_risk(self, risk_score: float) -> str:
        """Categorize risk level based on score"""
        if risk_score < 0.3:
            return "Low"
        elif risk_score < 0.7:
            return "Medium"
        else:
            return "High"
    
    def _generate_recommendations(self, risks: Dict) -> List[str]:
        """Generate risk mitigation recommendations"""
        recommendations = []
        
        if risks["smart_contract_risk"] > 0.6:
            recommendations.append("Consider waiting for additional audits before investing")
        
        if risks["liquidity_risk"] > 0.6:
            recommendations.append("Be cautious of low liquidity - consider smaller position sizes")
        
        if risks["market_risk"] > 0.6:
            recommendations.append("High volatility detected - consider hedging strategies")
        
        if risks["counterparty_risk"] > 0.6:
            recommendations.append("High user concentration - monitor for large withdrawals")
        
        if risks["governance_risk"] > 0.6:
            recommendations.append("Centralized governance - monitor for governance attacks")
        
        if not recommendations:
            recommendations.append("Protocol appears to have acceptable risk levels")
        
        return recommendations
