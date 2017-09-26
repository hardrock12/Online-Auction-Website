require 'digest/sha1'
require 'net/http'
require "erb"

include ERB::Util

 

class MainController < ApplicationController
 before_action :require_login, only: [:profile]

def setmessage
	if(session[:em].nil?)

		session[:em]=[]
		@msgarr=[]
		return
	else
		@msgarr=session[:em]
		session[:em]=[]
	end
end
def index
setmessage()

@category=Category.all

@r=Product.all
@au="AUCTION_LIVE"
@st=Product.where(:auction_status=>@au)
@du=[]
@st.each do |c|
@du.push (c.end_time-ActiveSupport::TimeZone["Asia/Kolkata"].now)

end

@ns="SCHEDULED"
@nst=Product.where(:auction_status=>@ns)

end


def get_hash(password,has)

strs=password+has
Digest::SHA1.hexdigest strs



end
 def profile
 	if (params[:id].nil?  or params[:id]=="")

 	if session[:userdata].nil?
 		redirect_to action:"index"
 		return
 	end

 	id=session[:userdata]["id"]
 
else
	id=params[:id]
end
@us=User.find(id)
@pro=Product.where(:seller_id=>@us.id)
@co=@pro.size
 end

 
def login
	if (request.method=="GET" )

		if(not session[:userdata].nil?)
				redirect_to action:"index"
		end
		#print form
		setmessage()

	elsif (request.method=="POST")


	session[:isadmin]=0
		@err=[]

		#user authenticate
		if(params[:email].empty? or params[:password].empty?)
			@err.push("Fields can't be blank");
		end
		@email=params[:email]
		if(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/.match(@email).nil?or /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/.match(@email).size==0)
			@err.push("Email InValid");

		end

		if(@err.size>0)

			session[:em]=@err
			redirect_to action:"login"

		else

			#check in db
			@us=User.where(:email=>params[:email])
			if( @us.size>0)
					@us=@us[0]
						if(@us.pwd==get_hash(params[:password],@us.salt.to_s))
							
								session[:userdata]=@us
							if(@us.verified_by==-3)
								redirect_to action:"ban"
							elsif(@us.verified_by<0)
								redirect_to action:"userverify"
							else
									if(Admin.where(:email=>params[:email]).size>0)

											session[:isadmin]=1
											session[:userdata]=@us
											redirect_to controller:"admin",action:"index"
											return
									end
									session[:isadmin]=0
									session[:userdata]=@us
									if(not session[:prevurl].nil?)

									redirect_to session[:prevurl]
									else
									redirect_to action:"index"	
									#redirect_to session[:prevurl]	
									end
							end
						else
						

							@err.push("Password Incorrect")
							session[:em]=@err
							redirect_to action:"login"
						end
		

			else

				@err.push("Email ID is not in database")
				session[:em]=@err
				redirect_to action:"login"

			end
		end
end
	



end
def register



end
def search_pro

	 @search_value = params[:searchterm].downcase
	 @cat=params[:category]
	 if params[:category].eql?("Category")

	 @r=Product.where("LOWER(name) like ? or LOWER(description) like ?","%#{@search_value}%","%#{@search_value}%")
	 else

	 @r=Product.where(:category=>@cat).where("LOWER(name) like ? or LOWER(description) like ?","%#{@search_value}%","%#{@search_value}%")
	 
end
	 @category = Category.all
end
	
def logout
	session[:isadmin]=nil
	session[:userdata]=nil
	redirect_to action:"index"

end
def userverify
	end
def verify

has=params[:id]
 @user=Verify.where(:code=>has).where(:expired=>0) 
if(@user.size==0)

	@mess="Verification Link is Invalid"
else
	@u=User.find(@user[0].userid)
	@u.verified_by=-1
	@u.save
	@user[0].expired=1
	@user[0].save
	@mess="User Verified Successfully"
end

	end
def registercomplete
	@msgarr=[]


	if (request.method=="GET")
		
		
		setmessage()
	elsif (request.method=="POST")

		@err=[]

		n1=params[:fname]
		n2=params[:lname]
		ad=params[:addr]
		em=params[:email]
		ph=params[:mobno]
		pwd=params[:pwd]	
		if(n1.empty? or n2.empty? or ad.empty? or ph.empty? or em.empty? or pwd.empty?)
			@err.push('All Fields cannot be Empty')
		end
		if(ph.length!=10)
			@err.push("Mobile No Invalid");
			end
		if(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/.match(em).nil? or /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/.match(em).size==0)
			@err.push('Email is Invalid')
		end
		if(@err.size>0)
			session[:em]=@err

			redirect_to action:"registercomplete"
		elsif (User.where(:email=>params[:email]).size!=0)
				@err.push("Email ID Already exists")
		session[:em]=@err

			redirect_to action:"registercomplete"
			
		else
			@user=User.new

			@user.name=params[:fname]+params[:lname]
			@user.addr=params[:addr]
			@user.phno=params[:mobno]
			@user.email=params[:email]
			slt=rand(99999).to_s
			@user.salt=slt
			@user.pwd=get_hash(params[:pwd],slt)
			@user.gender=params[:gender]
			@user.verified_by=-2
			@user.usertype="user"
			@user.save

body ="<h2>Online Auction System</h2></h4>Verify Email</h4> <p>Please click link <a href=\""
baki="\" >Here</a> to verify email.</p>"
hash1=get_hash(rand(999999).to_s,"verified_by")
@v=Verify.new
@v.userid=@user.id
@v.code=hash1
@v.expired=0
@v.date=Time.now+1.day
@v.save

ip=Socket.ip_address_list.detect{|intf| intf.ipv4_private?}
if ip
ipaddr=ip.ip_address
else
ipaddr="localhost"
end 
url1="http://"+ipaddr+":3000/verify/"+hash1
message=body+url1+baki
host='http://www.advancedbytes.in'
furl=host+'/sendmail?semail=123arjunsuresh@gmail.com&remail='+em+"&body="+message+"&sub=Verify Email"

#furl= url_encode(furl)
puts(furl)

system("python main.py '"+furl+"'")
#http = Net::HTTP.new("www.advancedbytes.in", 80)
#req = Net::HTTP::Get.new(furl, {'User-Agent' => 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:55.0) Gecko/20100101 Firefox/55.0'})
#response = http.request(req)
#puts response.body

			redirect_to action:"regsucess"
		end
		#insert to db
 

		
	end	
end	
def regsucess


	end
def search 


end
def loginfail


	end


	def loginsucess

	end



end


